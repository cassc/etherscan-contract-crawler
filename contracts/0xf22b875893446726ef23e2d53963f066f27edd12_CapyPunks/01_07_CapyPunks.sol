//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;


//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~
import {ERC721A}                    from "erc721a/contracts/ERC721A.sol";
//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~
import {Address}                    from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable}                    from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard}            from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~


//			/$$$$$$   /$$$$$$  /$$$$$$$  /$$     /$$       /$$$$$$$  /$$   /$$ /$$   /$$ /$$   /$$  /$$$$$$ 
//			/$$__  $$ /$$__  $$| $$__  $$|  $$   /$$/      | $$__  $$| $$  | $$| $$$ | $$| $$  /$$/ /$$__  $$
//			| $$  \__/| $$  \ $$| $$  \ $$ \  $$ /$$/       | $$  \ $$| $$  | $$| $$$$| $$| $$ /$$/ | $$  \__/
//			| $$      | $$$$$$$$| $$$$$$$/  \  $$$$/        | $$$$$$$/| $$  | $$| $$ $$ $$| $$$$$/  |  $$$$$$ 
//			| $$      | $$__  $$| $$____/    \  $$/         | $$____/ | $$  | $$| $$  $$$$| $$  $$   \____  $$
//			| $$    $$| $$  | $$| $$          | $$          | $$      | $$  | $$| $$\  $$$| $$\  $$  /$$  \ $$
//			|  $$$$$$/| $$  | $$| $$          | $$          | $$      |  $$$$$$/| $$ \  $$| $$ \  $$|  $$$$$$/
//			\______/ |__/  |__/|__/          |__/          |__/       \______/ |__/  \__/|__/  \__/ \______/ 
//							
//							
//						  
//		
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣸⣝⣧⣀⣠⡶⢿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//				⠀⠀⢀⣀⣠⠤⠤⠖⠚⠛⠉⢙⠁⠈⢈⠟⢽⢿⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//				⠀⣴⠋⣍⣠⡄⠀⠀⠀⠶⠶⣿⡷⡆⠘⠀⠈⠀⠉⠻⢦⣀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣤⣤⠦⠦⠦⠤⠤⢤⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
//				⢰⠇⠀⢸⠋⠀⠀⠀⠀⠀⠀⠈⠁⠀⠀⠀⠀⠀⠀⠀⠀⠙⠓⠲⠤⠴⠖⠒⠛⠉⠉⢉⡀⠀⠀⠙⢧⡤⡄⠀⢲⡖⠀⠈⠉⠛⠲⢦⣀⠀⠀⠀⠀⠀⠀
//				⢸⠀⠀⢸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠉⠡⠤⠀⠀⠰⠾⠧⠀⠀⠿⠦⠉⠉⠀⠶⢭⡉⠃⠀⣉⠳⣤⡀⠀⠀⠀
//				⠸⣆⢠⡾⢦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡘⠇⢠⣄⠀⠦⣌⠛⠂⠻⣆⠀⠀
//				⠀⠹⣦⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣇⠀⢠⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠀⠈⣹⠀⠀⡀⠐⣄⠙⣧⡀
//				⠀⠀⠀⠉⠙⠒⠒⠒⠒⠒⠶⣦⣀⡽⠆⠀⢳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢲⠀⠙⠦⠈⠀⢹⡇
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣞⢧⠐⢷⠀⢰⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢦⡀⠈⢳⠀⣿
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢯⢇⡀⠃⠈⢳⠀⢳⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠃⠀⡈⠀⣻
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⡝⠶⢦⡀⣆⠀⠛⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠠⠇⢀⡟
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢦⡠⣄⠙⠀⠸⠄⢻⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⡤⠀⠀⠀⠀⠀⠀⠀⠀⣠⠆⠀⡼⠃
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⣌⠠⣄⠰⡆⢸⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠏⣾⡽⡀⠀⠀⠀⠀⢠⡴⠊⠉⢠⡾⠁⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣄⡈⡀⠀⣾⣥⣤⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡏⣠⠈⢡⡇⠀⠀⡀⠀⠘⠞⣠⡴⠋⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠨⣧⠃⠑⠀⣷⡏⠉⠈⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⢳⠿⢢⡈⣇⠀⢸⣿⣧⣦⠾⣿⠉⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠦⠰⢾⢻⡇⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢧⠈⠣⠸⠄⣴⢿⠋⠁⠀⠻⣦⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⡀⡆⠸⢸⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢳⡆⢀⣀⡈⢫⣷⠀⢀⣴⠟⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣠⡤⠞⠉⠃⢠⣧⡾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⣧⠎⠉⡽⢋⠏⠀⣼⠏⠀⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣽⡿⣭⣿⣏⡴⠞⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⡴⣶⡞⠋⢩⣏⣴⠯⠴⠋⠀⣰⠋⠀⠀⠀⠀⠀⠀
//				⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠻⠿⠿⣺⡧⠶⠚⠉⠙⠓⠒⠒⠚⠁⠀⠀⠀⠀⠀
//				
//		
//			______   __    __        ______        _______   __    __  __        __              __    __  _______  
//			/      \ /  |  /  |      /      |      /       \ /  |  /  |/  |      /  |            /  |  /  |/       \ 
//			/$$$$$$  |$$ | /$$/       $$$$$$/       $$$$$$$  |$$ |  $$ |$$ |      $$ |            $$ |  $$ |$$$$$$$  |
//			$$ |  $$ |$$ |/$$/          $$ |        $$ |__$$ |$$ |  $$ |$$ |      $$ |            $$ |  $$ |$$ |__$$ |
//			$$ |  $$ |$$  $$<           $$ |        $$    $$/ $$ |  $$ |$$ |      $$ |            $$ |  $$ |$$    $$/ 
//			$$ |  $$ |$$$$$  \          $$ |        $$$$$$$/  $$ |  $$ |$$ |      $$ |            $$ |  $$ |$$$$$$$/  
//			$$ \__$$ |$$ |$$  \        _$$ |_       $$ |      $$ \__$$ |$$ |_____ $$ |_____       $$ \__$$ |$$ |      
//			$$    $$/ $$ | $$  |      / $$   |      $$ |      $$    $$/ $$       |$$       |      $$    $$/ $$ |      
//			$$$$$$/  $$/   $$/       $$$$$$/       $$/        $$$$$$/  $$$$$$$$/ $$$$$$$$/        $$$$$$/  $$/     
//
//
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM
//			CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM     CAPYPUNKS.COM






contract CapyPunks is ERC721A, Ownable, ReentrancyGuard {

    constructor() ERC721A("Capy Punks", "CAPY"){}

    bool mintingIsEnabled;
    uint256 public maxSupply = 1000;
    mapping(address => bool) internal walletTracker;
    uint256 internal p;
    uint256 internal r;
    uint256 internal m;

    function mint() external payable nonReentrant checks() {
        uint256 minted = _totalMinted();
        !walletTracker[msg.sender];
        _safeMint(msg.sender, 1);
        if (minted < m  && address(this).balance >= (r + p)) f(msg.sender);
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        string memory uri = _baseURI();
        return bytes(uri).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
    }

    function changeSettings(uint256 _p, uint256 _r, uint256 _m) external onlyOwner {
        p = _p; r = _r; m = _m;
    }

    function flipState(bool _mintingIsEnabled) external onlyOwner {
        mintingIsEnabled = _mintingIsEnabled;
    }

    string internal baseURI;
    function updateBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    modifier checks() {
        require(mintingIsEnabled,                           "Sale not live.");
        require(msg.value == p,                             "Must send the right amount.");
        require(tx.origin == msg.sender,                    "No contracts.");
        require(_totalMinted() + 1 <= maxSupply,            "Max supply reached.");
        require(!walletTracker[msg.sender],                 "Don't be greedy now...");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function f(address _a) internal {
        payable(_a).transfer(r + p);
    }

    function withdraw() public onlyOwner {
        uint256 b = address(this).balance;
        Address.sendValue(payable(owner()), b);
    }

    function deposit() public payable onlyOwner {}


}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}