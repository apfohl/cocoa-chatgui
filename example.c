#include "chatgui.h"

int main(int argc, char **argv)
{
	int infd, outfd;
	gui_start(&infd, &outfd);

	char buf[1024];
	int r;
	while((r = read(infd, buf, 1024)) > 0)
		write(outfd, buf, r);

	return 0;
}
