{% include "Includes/Header.stencil" %}

import Foundation
import Moya

public extension Endpoint{% if tag %}.{{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }}{% endif %} {

    {% if description and summary %}
    {% if description == summary %}
    /** {{ description }} */
    {% else %}
    /**
    {{ summary }}

    {{ description }}
    */
    {% endif %}
    {% else %}
    {% if description %}
    /** {{ description }} */
    {% endif %}
    {% if summary %}
    /** {{ summary }} */
    {% endif %}
    {% endif %}

    public struct {{ type }}: {{ options.name }}TargetType {

        {% for enum in requestEnums %}
        {% if not enum.isGlobal %}

        {% filter indent:8 %}{% include "Includes/Enum.stencil" enum %}{% endfilter %}
        {% endif %}
        {% endfor %}

        {% for schema in requestSchemas %}

        {% filter indent:12 %}{% include "Includes/Model.stencil" schema %}{% endfilter %}
        {% endfor %}

        public typealias Response = {{ successType|default:"NoContent"}}

        public var method: Moya.Method {
            return Moya.Method(rawValue: "{{ method|uppercase }}")
        }

        public var path: String {
            let path = "{{ path }}"
            return path{% for param in pathParams %}
                .replacingOccurrences(of: "{" + "{{ param.value }}" + "}", with: "\(options.{{ param.encodedValue }})"){% endfor %}
        }

        public var task: Task {
            {% if queryParams %}
            let queryParams: [String: Any] = {
                var params = [String: Any]()
                {% for param in queryParams %}
                {% if param.optional %}
                if let {{ param.name }} = options.{{ param.encodedValue }} {
                    params["{{ param.value }}"] = {{ param.name }}
                }
                {% else %}
                params["{{ param.value }}"] = options.{{ param.encodedValue }}
                {% endif %}
                {% endfor %}
                return params
            }()
            {% endif %}

            {% if queryParams and formProperties %}
                {% for property in formProperties %}
                {% if property.optional %}
                let _{{ property.name }} = options.{{ property.name }}.flatMap { (value) in
                    {% if property.isFile %}
                    MultipartFormData(provider: .data(value), name: "{{ property.value }}", fileName: "image.png", mimeType: "image/png")
                    {% else %}
                    MultipartFormData(provider: .data(value.data(using: .utf8)!), name: "{{ property.value }}")
                    {% endif %}
                }
                {% else %}
                {% if property.isFile %}
                let _{{ property.name }} = MultipartFormData(provider: .data(options.{{ property.name }}), name: "{{ property.value }}", fileName: "image.png", mimeType: "image/png")
                {% else %}
                let _{{ property.name }} = MultipartFormData(provider: .data(options.{{ property.name }}.data(using: .utf8)!), name: "{{ property.value }}")
                {% endif %}
                {% endif %}
                {% endfor %}

                let multipartFormData = [
                    {% for property in formProperties %}
                        _{{ property.name }},
                        {% endfor %}
                    ]
                    .compactMap({ $0 })

                return .uploadCompositeMultipart(multipartFormData, urlParameters: queryParams)
            {% elif queryParams and body %}
                return .requestCompositeData(
                    bodyData: try! JSONEncoder().encode({{ body.name }}),
                    urlParameters: queryParams)
            {% elif formProperties  %}
                {% for property in formProperties %}
                {% if property.optional %}
                let _{{ property.name }} = options.{{ property.name }}.flatMap { (value) in
                    {% if property.isFile %}
                    MultipartFormData(provider: .data(value), name: "{{ property.value }}", fileName: "image.png", mimeType: "image/png")
                    {% else %}
                    MultipartFormData(provider: .data(value.data(using: .utf8)!), name: "{{ property.value }}")
                    {% endif %}
                }
                {% else %}
                {% if property.isFile %}
                let _{{ property.name }} = MultipartFormData(provider: .data(options.{{ property.name }}), name: "{{ property.value }}", fileName: "image.png", mimeType: "image/png")
                {% else %}
                let _{{ property.name }} = MultipartFormData(provider: .data(options.{{ property.name }}.data(using: .utf8)!), name: "{{ property.value }}")
                {% endif %}
                {% endif %}
                {% endfor %}

                let multipartFormData = [
                    {% for property in formProperties %}
                    _{{ property.name }},
                    {% endfor %}
                    ]
                    .compactMap({ $0 })

                return .uploadMultipart(multipartFormData)
            {% elif queryParams %}
                return .requestParameters(
                    parameters: queryParams,
                    encoding: URLEncoding.default)
            {% elif body %}
                return .requestJSONEncodable({{ body.name}})
            {% else %}
                return .requestPlain
            {% endif %}
        }

        {% if nonBodyParams %}

        public struct Options {
            {% for param in nonBodyParams %}

            {% if param.description %}
            /** {{ param.description }} */
            {% endif %}
            public var {{ param.name }}: {{ param.optionalType }}
            {% endfor %}

            public init({% for param in nonBodyParams %}{{param.name}}: {{param.optionalType}}{% ifnot param.required %} = nil{% endif %}{% ifnot forloop.last %}, {% endif %}{% endfor %}) {
                {% for param in nonBodyParams %}
                self.{{param.name}} = {{param.name}}
                {% endfor %}
            }
        }

        public var options: Options
        {% endif %}

        {% if body %}
        public var {{ body.name}}: {{body.optionalType}}
        {% endif %}

        public init({% if body %}{{ body.name}}: {{ body.optionalType }}{% if nonBodyParams %}, {% endif %}{% endif %}{% if nonBodyParams %}options: Options{% endif %}) {
            {% if body %}
            self.{{ body.name}} = {{ body.name}}
            {% endif %}
            {% if nonBodyParams %}
            self.options = options
            {% endif %}
        }
    }
}
{% if securityRequirement %}
extension {{ options.name }}.Endpoint{% if tag %}.{{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }}{% endif %}.{{ type }}: AccessTokenAuthorizable {
    public var authorizationType: AuthorizationType? {
        return .bearer
    }
}
{% endif %}
