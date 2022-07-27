//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;



import {ProxyQuery, OSI}            from "./Interfaces.sol"; 
import {OnChainMetadata}            from "./Interfaces.sol";
//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~
import {ERC721A}                    from "erc721a/contracts/ERC721A.sol";
import {ERC721ABurnable}            from "erc721a/contracts/extensions/ERC721ABurnable.sol";
import {ERC721AQueryable}           from "erc721a/contracts/extensions/ERC721AQueryable.sol";
//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~//~~
import {Address}                    from "@openzeppelin/contracts/utils/Address.sol";
import {Ownable}                    from "@openzeppelin/contracts/access/Ownable.sol";
import {MerkleProof}                from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ReentrancyGuard}            from "@openzeppelin/contracts/security/ReentrancyGuard.sol";



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






contract CapyPunks is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard {


    constructor() ERC721A("Capy Punks", "CAPY"){}


    bool mintingIsEnabled;
    uint256 public maxSupply = 5000;
    uint256 public price = 0.02 ether;
    mapping(address => uint256) internal walletTracker;


    function hupHup(uint256 _amount, uint160 _secret) external payable nonReentrant checks(_amount, _secret) {
        if (_totalMinted() >= 1000) {
            require(msg.value / _amount == price, "Incorrect amount sent. Mint is free.");
        } else {
            require(msg.value == 0, "Must send 0 if supply minted is under 1,000.");
        }
        walletTracker[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }


    function hupHupHup(uint256 _amount, uint160 _secret, bytes32[] calldata _proof) external nonReentrant checks(_amount, _secret) {
        require(MerkleProof.verify(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not enough CC0 in your blood.");
        walletTracker[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);
    }


    function getMessage(uint256 _index) public view returns (string memory) {
        return messages[_index];
    }


    function getLatestMessage() public view returns (string memory) {
        require(msgCount > 0);
        return messages[msgCount - 1];
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
        if (metadataIsOnChain == true) {
            return OnChainMetadata(metadataAddress).tokenURI(tokenId);
        } else {
            string memory uri = _baseURI();
            return bytes(uri).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId), ".json")) : '';
        }
    }


    mapping(uint256 => string) internal messages;
    uint256 internal msgCount;
    function message(string memory _message) public onlyOwner {
        messages[msgCount] = _message;
        msgCount++;
    }

    function hup(uint256 _amount) external onlyOwner {
        require(_totalMinted() + _amount <= maxSupply);
        require(_amount > 0);
        _safeMint(msg.sender, _amount);
    }

    function flipState(bool _saleActive, bool _checkRegistration) external onlyOwner {
        mintingIsEnabled = _saleActive;
        checkRegistration = _checkRegistration;
    }

    address public metadataAddress;
    function addMetadataContract(address _contract) external onlyOwner {
        require(!permanentMetadataSwitch);
        metadataAddress = _contract;
    }

    bool public metadataIsOnChain;
    function toggleOnChainMetadata(bool _bool) external onlyOwner {
        require(!permanentMetadataSwitch);
        metadataIsOnChain = _bool;
    }

    bool internal permanentMetadataSwitch;
    function permanentlyFreezeMetadata() external onlyOwner {
        require(metadataIsOnChain);
        permanentMetadataSwitch = true;
    }

    function updatePrice(uint256 _price) external onlyOwner {   
        price = _price;
    }

    string internal baseURI;
    function updateBaseURI(string memory _newURI) external onlyOwner {
        baseURI = _newURI;
    }

    bytes32 internal merkleRoot;
    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }
    
    address internal proxyAddress;
    function setProxyVerifier(address _address) external onlyOwner {
        proxyAddress = _address;
    }

    function getProxyAddress(address _addr) internal view returns (uint160) {
        return ProxyQuery(proxyAddress).query(_addr);
    }

    bool internal checkRegistration;
    function isRegistered(address _address) internal view returns (bool) {
        if (!checkRegistration) {
            return true;
        } else {
            return OSI(0xa5409ec958C83C3f309868babACA7c86DCB077c1).proxies(_address) != 0x0000000000000000000000000000000000000000;
        }
    }

    modifier checks(uint256 _amount, uint160 _proxy) {
        require(mintingIsEnabled,                           "You can't pull up right now.");
        require(tx.origin == msg.sender,                    "4E6F20636F6E7472616374732E");
        require(isRegistered(msg.sender),                   "Inactive wallet.");
        require( _proxy == getProxyAddress(msg.sender),     "Invalid Proxy Authentication");
        require(_totalMinted() + _amount <= maxSupply,      "Supply cap reached...");
        require(_amount > 0,                                "Maybe try minting more than 1?");
        require(_amount + walletTracker[msg.sender] <= 5,   "Don't be greedy now...");
        _;
    }

    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function withdraw() public onlyOwner {
        uint256 b = address(this).balance;
        Address.sendValue(payable(owner()), b);
    }


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