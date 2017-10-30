attribute vec4 Position;
attribute vec4 SourceColor;

varying vec4 DestinationColor;

uniform mat4 Projection;
uniform mat4 World;

void main(void) {
    DestinationColor = 0.5 * SourceColor;
    gl_Position = Projection * World * Position;
}

