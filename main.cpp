#include <iostream>
#include <boost/filesystem.hpp>

using namespace boost::filesystem;

int main(int argc, char* argv[]) {
    if (argc < 2) {
        std::cout << "Usage: emsdkbug <filename>\n";
        return 1;
    }

    if (exists(argv[1])) {
        std::cout << argv[1] << " " << file_size(argv[1]) << '\n';
    } else {
        std::cout << argv[1] << " does not exist\n";
    }
    
    return 0;
}