{% include "Includes/Header.stencil" %}

import Foundation
import Moya

{% if info.description %}
/** {{ info.description }} */
{% endif %}
public enum Endpoint {
{% if tags %}
{% for tag in tags %}
    public enum {{ options.tagPrefix }}{{ tag|upperCamelCase }}{{ options.tagSuffix }} {}
{% endfor %}
{% endif %}
}
