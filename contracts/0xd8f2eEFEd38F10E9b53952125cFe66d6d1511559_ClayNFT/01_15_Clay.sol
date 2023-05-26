// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./ERC721A.sol";
import "./extensions/ERC721AOwnersExplicit.sol";

/**
      ___                         ___                 
     /\__\                       /\  \                
    /:/  /                      /::\  \         ___   
   /:/  /                      /:/\:\  \       /|  |  
  /:/  /  ___   ___     ___   /:/ /::\  \     |:|  |  
 /:/__/  /\__\ /\  \   /\__\ /:/_/:/\:\__\    |:|  |  
 \:\  \ /:/  / \:\  \ /:/  / \:\/:/  \/__/  __|:|__|  
  \:\  /:/  /   \:\  /:/  /   \::/__/      /::::\  \  
   \:\/:/  /     \:\/:/  /     \:\  \      ~~~~\:\  \ 
    \::/  /       \::/  /       \:\__\          \:\__\
     \/__/         \/__/         \/__/           \/__/

  By Kai from nanoverseHQ

  Parts borrowed/inspired by:
  MouseDev https://etherscan.io/address/0xbad6186E92002E312078b5a1dAfd5ddf63d3f731#code
  0xinuarashi https://etherscan.io/address/0x4956013f250758B73c3BBa4bC6539db7a0AD6B66#code
 */

interface IClayTraitModifier {
  function renderAttributes(uint256 _t) external view returns (string memory);
}

contract ClayNFT is Ownable, ERC721A, ERC721AOwnersExplicit, ReentrancyGuard {
    using ECDSA for bytes32;

    uint256 public immutable maxSupply = 3333;
    uint256 public wlPrice = 0.1 ether;
    uint256 public publicPrice = 0.15 ether;
    
    enum SalePhase {
        Locked,
        PreSale,
        PreSaleAndFreeMint,
        PublicSale
    }
    SalePhase public phase = SalePhase.Locked;
    
    address private wlMintSigner;
    address private freeMintSigner;

    string public baseHTML;
    string public placeholderHTML;
    string public endHTML;

    string public overrideAnimationUrl;
    string public overrideImageUrl;

    bool public usePlaceholder = true;
    uint256 public metadataSeed;
    address public traitModifierContract;

    struct Trait {
        string traitName;
        string traitType;
    }

    //Mappings
    mapping(uint256 => Trait[]) public traitTypes;    
    mapping(address => uint256) private wlMintAlreadyMint;
    mapping(address => uint256) private freeMintAlreadyMint;

    //uint arrays
    uint16[][6] TIERS;

    constructor() ERC721A("ClayNFT", "ClayNFT") {
      //Base
      TIERS[0] = [4000, 3000, 2000, 1000];
      //Ore
      TIERS[1] = [5000, 1500, 1500, 750, 750, 200, 200, 90, 10];
      //HasEyes
      TIERS[2] = [8000, 2000];
      //HasMouth
      TIERS[3] = [9000, 1000];
      //BgColor
      TIERS[4] = [2000, 2000, 1500, 1500, 1500, 1500];
      //LargeOre
      TIERS[5] = [7500, 2500];
    }

    /***
     *     _______  __   __  _______  _______    __   __  _______  ___   ___
     *    |       ||  | |  ||       ||       |  |  | |  ||       ||   | |   |
     *    |_     _||  |_|  ||    _  ||    ___|  |  | |  ||_     _||   | |   |
     *      |   |  |       ||   |_| ||   |___   |  |_|  |  |   |  |   | |   |
     *      |   |  |_     _||    ___||    ___|  |       |  |   |  |   | |   |___
     *      |   |    |   |  |   |    |   |___   |       |  |   |  |   | |       |
     *      |___|    |___|  |___|    |_______|  |_______|  |___|  |___| |_______|
     */

    // Base64 Encoder
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encodeBase64(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);
        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }
        return result;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function parseInt(string memory _a)
        internal
        pure
        returns (uint8 _parsedInt)
    {
        bytes memory bresult = bytes(_a);
        uint8 mint = 0;
        for (uint8 i = 0; i < bresult.length; i++) {
            if (
                (uint8(uint8(bresult[i])) >= 48) &&
                (uint8(uint8(bresult[i])) <= 57)
            ) {
                mint *= 10;
                mint += uint8(bresult[i]) - 48;
            }
        }
        return mint;
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }

    function isNotEmpty(string memory str) internal pure returns (bool) {
      return bytes(str).length > 0;
    }

    /***
     *     __   __  _______  _______  _______  ______   _______  _______  _______
     *    |  |_|  ||       ||       ||   _   ||      | |   _   ||       ||   _   |
     *    |       ||    ___||_     _||  |_|  ||  _    ||  |_|  ||_     _||  |_|  |
     *    |       ||   |___   |   |  |       || | |   ||       |  |   |  |       |
     *    |       ||    ___|  |   |  |       || |_|   ||       |  |   |  |       |
     *    | ||_|| ||   |___   |   |  |   _   ||       ||   _   |  |   |  |   _   |
     *    |_|   |_||_______|  |___|  |__| |__||______| |__| |__|  |___|  |__| |__|
     */

    function generateMetadataHash(uint256 _t, uint256 _c)
        internal
        view
        returns (string memory)
    {
        string memory currentHash = "";
        for (uint8 i = 0; i < 6; i++) {
            uint16 _randinput = uint16(
                uint256(keccak256(abi.encodePacked(_t, _c))) % 10000
            );

            currentHash = string(
                abi.encodePacked(currentHash, rarityGen(_randinput, i))
            );
        }

        return currentHash;
    }

    function rarityGen(uint256 _randinput, uint8 _rarityTier)
        internal
        view
        returns (string memory)
    {
        uint16 currentLowerBound = 0;
        for (uint8 i = 0; i < TIERS[_rarityTier].length; i++) {
            uint16 thisPercentage = TIERS[_rarityTier][i];
            if (
                _randinput >= currentLowerBound &&
                _randinput < currentLowerBound + thisPercentage
            ) return toString(i);
            currentLowerBound = currentLowerBound + thisPercentage;
        }

        revert();
    }

    function renderAttributesFromHash(string memory _hash, uint256 _t) public view returns (string memory) {
      require(_t < totalSupply(), 'Token does not exist');

      if(usePlaceholder) {
        return '[]';
      }

      // Allows upgrade to trait metadata in later phases
      if(traitModifierContract != address(0)) {
        IClayTraitModifier c = IClayTraitModifier(traitModifierContract);
        return c.renderAttributes(_t);
      }

      uint256 seed = uint256(keccak256(abi.encodePacked(_t, metadataSeed))) % 100000;

      string memory metadataString;
      for (uint8 i = 0; i < 6; i++) {
          uint8 thisTraitIndex = parseInt(substring(_hash, i, i + 1));

          metadataString = string(
              abi.encodePacked(
                  metadataString,
                  '{"trait_type":"',
                  traitTypes[i][thisTraitIndex].traitType,
                  '","value":"',
                  traitTypes[i][thisTraitIndex].traitName,
                  '"}'
              )
          );

          metadataString = string(abi.encodePacked(metadataString, ","));
      }

      metadataString = string(
          abi.encodePacked(
              metadataString,
              '{"trait_type":"Seed","value":"',
              toString(seed),
              '"}'
          )
      );

      return string(abi.encodePacked("[", metadataString, "]"));
    }

    function renderAttributes(uint256 _t) public view returns (string memory) {
      string memory _hash = generateMetadataHash(_t, metadataSeed);
      return renderAttributesFromHash(_hash, _t);
    }

    string svgPrefix = 'data:image/svg+xml;base64,';

    function renderSVGFromHash(string memory _hash)
        public
        view
        returns (string memory)
    {
        uint8 baseTraitIndex = parseInt(substring(_hash, 0, 1));
        uint8 oreTraitIndex = parseInt(substring(_hash, 1, 2));
        uint8 largeOreTraitIndex = parseInt(substring(_hash, 5, 6));

        string[4] memory baseColors = [
            "rgb(130,101,82)",
            "rgb(77,83,87)",
            "rgb(121,126,139)",
            "black"
        ];

        string memory baseColor = baseColors[baseTraitIndex];

        string[9] memory oreColors = [
            baseColor,
            "rgb(70.9,195.5,82.8)",
            "rgb(181,129,68)",
            "rgb(170,218,170)",
            "rgb(195,155,65)",
            "rgb(255,0,30)",
            "rgb(39,100,255)",
            "rgb(148,42,235)",
            "white"
        ];

        string memory oreColor = oreColors[oreTraitIndex];

        string[2] memory oreSize = [
          '<path d="M196.947 188.849l28.058-28.744 11.648 1.592-37.16 38.578z" fill="',
          '<path d="M197.01 188.792l28.057-28.743 23.784 3.167-47.196 47.095z" fill="'
        ];
        
        bytes memory baseElement = abi.encodePacked(
          '<path d="M322.654 173.053L189.77 155.342l26.702 123.092-101.336 45.107 265.728 21.117-86.728-62.137z" fill="',
          baseColor,
          '"/>');

        bytes memory oreElement = abi.encodePacked(
          oreSize[largeOreTraitIndex],
          oreColor,
          '"/>');

        bytes memory svgString = 
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" width="500" height="500"><text font-family="sans-serif" font-size="56" font-weight="200" letter-spacing="-1.12" transform="translate(398.63 455.71)"><tspan x="-84.04" y="18.06">C</tspan><tspan x="-46.52" y="18.06">L</tspan><tspan x="-14.21" y="18.06">A</tspan><tspan x="19.9" y="18.06">Y</tspan><tspan x="55.29" y="18.06">_</tspan></text><text font-family="sans-serif" font-size="15" font-weight="300" transform="translate(248 19)"><tspan x="-66.87" y="2.28">Open to see 3D view</tspan></text>',
                usePlaceholder ? bytes('') : baseElement,
                usePlaceholder ? bytes('') : oreElement,
                '</svg>'
            );

        return string(abi.encodePacked(svgPrefix, encodeBase64(svgString)));
    }

    function renderSVG(uint256 tokenId)
      public
      view
      returns (string memory)
    {
      string memory _hash = generateMetadataHash(tokenId, metadataSeed);
      return renderSVGFromHash(_hash);
    }

    string htmlPrefix = "data:text/html;base64,";
    function getOnChainAnimationURIFromHash(string memory _hash, uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
      if (usePlaceholder) {
          return
              string(
                  abi.encodePacked(
                      htmlPrefix,
                      encodeBase64(bytes(placeholderHTML))
                  )
              );
      }

      return
          string(
              abi.encodePacked(
                  htmlPrefix,
                  encodeBase64(bytes(abi.encodePacked(
                    baseHTML, 
                    renderAttributesFromHash(_hash, tokenId),
                    endHTML)))
              )
          );
    }

    function getOnChainAnimationURI(uint256 tokenId)
        public
        view
        virtual
        returns (string memory)
    {
      string memory _hash = generateMetadataHash(tokenId, metadataSeed);
      return getOnChainAnimationURIFromHash(_hash, tokenId);
    }

    string public constant _metaHeader = "data:application/json;base64,";

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
      string memory _hash = generateMetadataHash(tokenId, metadataSeed);
      string memory _metadata = string(
          abi.encodePacked(
              '{"name":"',
              abi.encodePacked("CLAY #", toString(tokenId)),
              '", "description":"CLAY is a fully on-chain 3D generative art project. The code is the art, the art is the code.", "image": "'
          )
      );

      _metadata = string(
          abi.encodePacked(
              _metadata,
              isNotEmpty(overrideImageUrl) ? string(abi.encodePacked(overrideImageUrl, tokenId)) : renderSVGFromHash(_hash),
              '","attributes": '
          )
      );

      _metadata = string(
          abi.encodePacked(_metadata, renderAttributesFromHash(_hash, tokenId))
      );

      _metadata = string(
          abi.encodePacked(
              _metadata,
              ', "animation_url":"',
              isNotEmpty(overrideAnimationUrl) ? string(abi.encodePacked(overrideAnimationUrl, tokenId)) : getOnChainAnimationURIFromHash(_hash, tokenId),
              '"}'
          )
      );

      return
          string(
              abi.encodePacked(_metaHeader, encodeBase64(bytes(_metadata)))
          );
    }

    /***
     *     _______  _     _  __    _  _______  ______
     *    |       || | _ | ||  |  | ||       ||    _ |
     *    |   _   || || || ||   |_| ||    ___||   | ||
     *    |  | |  ||       ||       ||   |___ |   |_||_
     *    |  |_|  ||       ||  _    ||    ___||    __  |
     *    |       ||   _   || | |   ||   |___ |   |  | |
     *    |_______||__| |__||_|  |__||_______||___|  |_|
     */

    function devMint(uint256 quantity) external onlyOwner {
        require(totalSupply() + quantity <= maxSupply, "reached max supply");
        // It's dev mint so I don't care about gas
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(msg.sender, 1);
        }
    }

    //set signers
    function setSigners(address _wlMintSigner, address _freeMintSigner)
        external
        onlyOwner
    {
        wlMintSigner = _wlMintSigner;
        freeMintSigner = _freeMintSigner;
    }

    function setTraitModifierContract(address _traitModifierContract) public onlyOwner {
        traitModifierContract = _traitModifierContract;
    }

    function setBaseHTML(string calldata _baseHTML) public onlyOwner {
        baseHTML = _baseHTML;
    }

    function setEndHTML(string calldata _endHTML) public onlyOwner {
        endHTML = _endHTML;
    }

    function setPlaceholderHTML(string calldata _placeholderHTML)
        public
        onlyOwner
    {
        placeholderHTML = _placeholderHTML;
    }

    function setUsePlaceholder(bool _usePlaceholder) public onlyOwner {
        usePlaceholder = _usePlaceholder;
    }

    function setMetadataSeed(uint256 _metadataSeed) public onlyOwner {
        metadataSeed = _metadataSeed;
    }
    

    function setOverrideAnimationUrl(string calldata _overrideAnimationUrl) public onlyOwner {
      overrideAnimationUrl = _overrideAnimationUrl;
    }

    function setOverrideImageUrl(string calldata _overrideImageUrl) public onlyOwner {
      overrideImageUrl = _overrideImageUrl;
    }

    function setMintPhase(SalePhase phase_) external onlyOwner {
      phase = phase_;
    }

    function clearTraits() public onlyOwner {
      for (uint256 i = 0; i < 6; i++) {
        delete traitTypes[i];
      }
    }

    function addTraitType(uint256 _traitTypeIndex, Trait[] memory traits)
        public
        onlyOwner
    {
        for (uint256 i = 0; i < traits.length; i++) {
            traitTypes[_traitTypeIndex].push(
                Trait(traits[i].traitName, traits[i].traitType)
            );
        }

        return;
    }

    function withdraw() public onlyOwner {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }

    /***
     *     __   __  ___   __    _  _______  ___   __    _  _______
     *    |  |_|  ||   | |  |  | ||       ||   | |  |  | ||       |
     *    |       ||   | |   |_| ||_     _||   | |   |_| ||    ___|
     *    |       ||   | |       |  |   |  |   | |       ||   | __
     *    |       ||   | |  _    |  |   |  |   | |  _    ||   ||  |
     *    | ||_|| ||   | | | |   |  |   |  |   | | | |   ||   |_| |
     *    |_|   |_||___| |_|  |__|  |___|  |___| |_|  |__||_______|
     */
     
    function publicSaleMint()
      external
      payable
      callerIsUser
    {
        require(
            phase == SalePhase.PublicSale,
            "Public sale minting is not active"
        );
        require(
            1 + totalSupply() <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(
            publicPrice <= msg.value,
            "Amount sent is insufficient"
        );

        _safeMint(msg.sender, 1);
    }

    function wlMint(bytes calldata signature)
        external
        payable
        callerIsUser
    {
        require(phase == SalePhase.PreSale || phase == SalePhase.PreSaleAndFreeMint,
          "Presale minting not active");
        require(
            1 + totalSupply() <= maxSupply,
            "Purchase would exceed max tokens"
        );
        require(wlPrice <= msg.value, "Amount sent is insufficient");

        require(
            wlMintSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );

        require(wlMintAlreadyMint[msg.sender] == 0, "Already minted");

        wlMintAlreadyMint[msg.sender] = 1;
        _safeMint(msg.sender, 1);
    }

    function freeMint(bytes calldata signature)
      external
      payable
    {
        require(phase == SalePhase.PreSaleAndFreeMint, "Free mint not active");
        require(
            1 + totalSupply() <= maxSupply,
            "Purchase would exceed max tokens"
        );

        require(
            freeMintSigner ==
                keccak256(
                    abi.encodePacked(
                        "\x19Ethereum Signed Message:\n32",
                        bytes32(uint256(uint160(msg.sender)))
                    )
                ).recover(signature),
            "Signer address mismatch."
        );

        require(freeMintAlreadyMint[msg.sender] == 0, "Already minted");

        _safeMint(msg.sender, 1);
        freeMintAlreadyMint[msg.sender] = 1;
    }

    /***
     *     __   __  ___   _______  _______
     *    |  |_|  ||   | |       ||       |
     *    |       ||   | |  _____||       |
     *    |       ||   | | |_____ |       |
     *    |       ||   | |_____  ||      _|
     *    | ||_|| ||   |  _____| ||     |_
     *    |_|   |_||___| |_______||_______|
     */

    function setOwnersExplicit(uint256 quantity)
      external
      onlyOwner
      nonReentrant
    {
        _setOwnersExplicit(quantity);
    }

    function getOwnershipData(uint256 tokenId)
        external
        view
        returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function tokensOfOwner(
        address _owner,
        uint256 startId,
        uint256 endId
    ) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index = 0;
            for (uint256 tokenId = startId; tokenId < endId; tokenId++) {
                if (index == tokenCount) break;

                if (ownerOf(tokenId) == _owner) {
                    result[index] = tokenId;
                    index++;
                }
            }

            return result;
        }
    }

    modifier callerIsUser() {
      require(tx.origin == msg.sender, "The caller is another contract");
      _;
    }
}