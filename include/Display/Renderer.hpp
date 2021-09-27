#pragma once

#include <stdint.h>
#include <Display/Framebuffer.hpp>
#include <Fonts/PSF.hpp>

struct Point
{
    int32_t X;
    int32_t Y;
};

#define COLOUR_WHITE    0x00FFFFFF
#define COLOUR_BLACK    0x00000000
#define COLOUR_RED      0x00FF0000
#define COLOUR_GREEN    0x0000FF00
#define COLOUR_BLUE     0x000000FF

#define USER_COLOUR_BACK    0x0C1021
#define USER_COLOUR_FRONT   0xF8F8F8

// A wrapper class over the Framebuffer.
class Renderer
{
    public:
    Framebuffer Buffer;
    Point Cursor;
    PSF1 *Font; // The PSF1 font used to print strings.
    uint32_t ForegroundColour;
    uint32_t BackGroundColour;

    Renderer(Framebuffer framebuffer, PSF1 *font, uint32_t foregroundColour, uint32_t backgroundColour);
    void Printf(const char *format, ...);
    void PrintErrorf(const char *format, ...);
    void PutChar(const int32_t xOffset, const int32_t yOffset, const char character);
    void PutChar(const char character);
    void PutPixel(const int32_t xOffset, const int32_t yOffset, const uint32_t colour);
    void SetForegroundColour(const uint32_t colour);
    void SetBackgroundColour(const uint32_t colour);
    void SetCursor(const int32_t xOffset, const int32_t yOffset);
    void ClearScreen();
    void ScrollUp(const int32_t pixels);
};

extern Renderer MainRenderer;

// Wrapper around MainRenderer.Printf().
void printf(const char *format, ...);

// Wrapper around MainRenderer.PrintErrorf().
void errorf(const char *format, ...);