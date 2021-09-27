#include <Display/Renderer.hpp>
#include <Syscalls/Display.hpp>

void SysGetFore(Registers *regs)
{
    regs->RAX = MainRenderer.ForegroundColour;
}


void SysSetFore(Registers *regs)
{
    MainRenderer.SetForegroundColour((uint32_t) regs->RDX);
}


void SysGetBack(Registers *regs)
{
    regs->RAX = MainRenderer.BackGroundColour;
}


void SysSetBack(Registers *regs)
{
    MainRenderer.SetBackgroundColour((uint32_t) regs->RDX);
    MainRenderer.ClearScreen();
}


void SysGetRes(Registers *regs)
{
    regs->RAX = ((uint64_t) MainRenderer.Buffer.Width << 32) | MainRenderer.Buffer.Height;
}


void SysGetCrsr(Registers *regs)
{
    regs->RAX = ((uint64_t) MainRenderer.Cursor.X << 32) | MainRenderer.Cursor.Y;
}


void SysSetCrsr(Registers *regs)
{
    MainRenderer.Cursor.X = (int32_t) regs->R8;
    MainRenderer.Cursor.Y = (int32_t) regs->R9;
}


void SysDrawP(Registers *regs)
{
    MainRenderer.PutPixel((int32_t) regs->R8, (int32_t) regs->R9, (uint32_t) regs->R10);
}


void SysDrawL(Registers *regs)
{
    int32_t x1 = (int32_t) regs->RDI;
    int32_t y1 = (int32_t) regs->RSI;
    int32_t x2 = (int32_t) regs->R8;
    int32_t y2 = (int32_t) regs->R9;
    uint32_t colour = (uint32_t) regs->R10;

    if(x1 == x2)
    {
        if(y1 > y2)
        {
            int32_t temp = y1;
            y1 = y2;
            y2 = temp;
        }
        
        for(int32_t y = y1; y <= y2; y++) MainRenderer.PutPixel(x1, y, colour);
        return;
    }

    double slope = ((double) y2 - y1) / (x2 - x1);
    double intercept = y1 - slope * x1;
    if(x1 > x2)
    {
        int32_t temp = x1;
        x1 = x2;
        x2 = temp;
    }

    for(int32_t x = x1; x <= x2; x++) MainRenderer.PutPixel(x, (int32_t) (slope * x + intercept), colour);
}


void SysDrawR(Registers *regs)
{
    int32_t x1 = (int32_t) regs->RDI;
    int32_t y1 = (int32_t) regs->RSI;
    int32_t width = (int32_t) regs->R8;
    int32_t height = (int32_t) regs->R9;
    uint32_t colour = (uint32_t) regs->R10;

    for(int32_t x = x1; x < x1 + width; x++) 
    {
        MainRenderer.PutPixel(x, y1, colour);
        MainRenderer.PutPixel(x, y1 + height - 1, colour);
    }
    for(int32_t y = y1; y < y1 + height; y++) 
    {
        MainRenderer.PutPixel(x1, y, colour);
        MainRenderer.PutPixel(x1 + width - 1, y, colour);
    }
}