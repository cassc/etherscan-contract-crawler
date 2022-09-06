// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract abyss is ERC721, ERC721Enumerable, Ownable {
    string[] metadataParts = [
        "OG",
        "Member",
        "OG Access Pass ",
        "Expired OG Access Pass ",
        "Access Pass ",
        "Expired Access Pass ",
        "A private collective of skilled traders and investors navigating the web3 space. OG membership passes grant access to all community benefits while active as well as additional benefits exclusive to OG holders. Each OG membership runs on a 45 day renewal system and can be managed at anytime via our dashboard.",
        "A private collective of skilled traders and investors navigating the web3 space. Membership passes grant access to all community benefits while active. Each membership runs on a 30 day renewal system and can be managed at anytime via our dashboard.",
        "ipfs://QmfGkqGeWTTQu21ytfHtsqmjBRJie9giEQxa2UBdh7oBmF/",
        "ipfs://QmfGkqGeWTTQu21ytfHtsqmjBRJie9giEQxa2UBdh7oBmF/",
        ".png"
    ];

    uint256 public constant ogTokenEnd = 10;
    uint256 public maxSupply = 50;
    uint256 public price = 0.08 ether;
    uint256 public renewPrice = 0.08 ether;
    uint256 public currentOgMinted;
    uint256 public currentRegularMinted;
    uint256 public maxRenewMonths = 3;

    mapping(uint256 => uint256) public expireTime;
    mapping(address => bool) public hasMinted;

    bool public privateSale = false;
    bool public canRenew = true;

    bytes32 public merkleRoot;
    bytes32 public merkleRootOG;

    event passMinted(uint256 tokenId, uint256 _expireTime);
    event passRenewed(uint256 tokenId, uint256 _expireTime);

    constructor() ERC721("The Abyss", "ABYSS") {
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external payable {
        uint256 nextToMint = ogTokenEnd + currentRegularMinted + 1;
        require(privateSale, "Private sale not active");
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == msg.sender, "No contracts");
        require(!hasMinted[msg.sender], "Already minted");
        require(price == msg.value, "Invalid funds provided");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, node),
            "Invalid proof"
        );

        currentRegularMinted++;
        hasMinted[msg.sender] = true;
        expireTime[nextToMint] = block.timestamp + 30 days;
        _mint(msg.sender, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function ogMint(bytes32[] calldata _merkleProof) external payable {
        uint256 nextToMint = currentOgMinted + 1;
        require(privateSale, "Private sale not active");
        require(ogTokenEnd >= currentOgMinted + 1, "Exceeds max OG supply");
        require(tx.origin == msg.sender, "No contracts");
        require(!hasMinted[msg.sender], "Already minted");
        require(price == msg.value, "Invalid funds provided");

        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRootOG, node),
            "Invalid proof"
        );

        currentOgMinted++;
        hasMinted[msg.sender] = true;
        expireTime[nextToMint] = block.timestamp + 45 days;
        _mint(msg.sender, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function renewPass(uint256 _tokenId, uint256 _months) external payable {
        require(canRenew);
        require(tx.origin == msg.sender, "No contracts");
        uint256 cost = renewPrice * _months;
        require(msg.value == cost, "Invalid funds provided");
        require(_exists(_tokenId), "Token does not exist.");
        require(_months <= maxRenewMonths, "Too many months");
        require(_months > 0, "Cannot renew 0 months");
        require(msg.sender == ownerOf(_tokenId), "Cannot renew a pass you do not own.");

        uint256 _currentexpireTime = expireTime[_tokenId];

        if (_tokenId <= ogTokenEnd) {
            // og renew
            if (block.timestamp > _currentexpireTime) {
                // if pass is already expired
                expireTime[_tokenId] = block.timestamp + (_months * 45 days);
            } else {
                // if pass is not already expired
                require(expireTime[_tokenId] + (_months * 45 days) <= block.timestamp + (maxRenewMonths * 45 days), "Surpasses renew limit");
                expireTime[_tokenId] += (_months * 45 days);
            }
        } else {
            // regular renew
            if (block.timestamp > _currentexpireTime) {
                // if pass is already expired
                expireTime[_tokenId] = block.timestamp + (_months * 30 days);
            } else {
                // if pass is not already expired
                require(expireTime[_tokenId] + (_months * 30 days) <= block.timestamp + (maxRenewMonths * 30 days), "Surpasses renew limit");
                expireTime[_tokenId] += (_months * 30 days);
            }
        }
        emit passRenewed(_tokenId, expireTime[_tokenId]);
    }



    // only owner
    function setPrivateSale(bool _state) external onlyOwner {
        privateSale = _state;
    }

    function setCanRenew(bool _state) external onlyOwner {
        canRenew = _state;
    }

    function setMetadataParts(string[] memory metadataParts_) external onlyOwner {
        metadataParts = metadataParts_;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMerkleRootOG(bytes32 _merkleRootOG) external onlyOwner {
        merkleRootOG = _merkleRootOG;
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setRenewPrice(uint256 _renewPrice) external onlyOwner {
        renewPrice = _renewPrice;
    }

    function setMaxRenewMonths(uint256 _maxRenewMonths) external onlyOwner {
        maxRenewMonths = _maxRenewMonths;
    }

    function ownerMintRegular(address _receiver) external onlyOwner {
        uint256 nextToMint = ogTokenEnd + currentRegularMinted + 1;
        require(maxSupply >= totalSupply() + 1, "Exceeds max supply");
        require(tx.origin == msg.sender, "No contracts");

        currentRegularMinted++;
        hasMinted[_receiver] = true;
        expireTime[nextToMint] = block.timestamp + 30 days;
        _mint(_receiver, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function ownerMintOG(address _receiver) external onlyOwner {
        uint256 nextToMint = currentOgMinted + 1;
        require(ogTokenEnd >= currentOgMinted + 1, "Exceeds max OG supply");
        require(tx.origin == msg.sender, "No contracts");

        currentOgMinted++;
        hasMinted[_receiver] = true;
        expireTime[nextToMint] = block.timestamp + 45 days;
        _mint(_receiver, nextToMint);
        emit passMinted(nextToMint, expireTime[nextToMint]);
    }

    function ownerRenew(uint256 _tokenId, uint256 _days) external onlyOwner {
        require(tx.origin == msg.sender, "No contracts");
        require(_exists(_tokenId), "Token does not exist.");
        uint256 _currentexpiryTime = expireTime[_tokenId];

        if (block.timestamp > _currentexpiryTime) {
            // if pass is expired
            expireTime[_tokenId] = block.timestamp + (_days * 1 days);
        } else {
            // if pass isn't expired
            expireTime[_tokenId] += (_days * 1 days);
        }
        emit passRenewed(_tokenId, expireTime[_tokenId]);
    }

    function inactivePassScrub(uint256 _tokenId, address _receiver) external onlyOwner {
        require(_exists(_tokenId), "Token does not exist.");
        uint256 _currentexpiryTime = expireTime[_tokenId];
        require(_currentexpiryTime + 7 days < block.timestamp, "Pass needs to be inactive for 7+ days");
        address person = ownerOf(_tokenId);

        safeTransferFrom(person, _receiver, _tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }



    // misc    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function checkPass(uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expireTime[_tokenId] > block.timestamp, "Pass is expired.");

        return msg.sender == ownerOf(_tokenId) ? true : false;
    }

    function checkUserWithPass(address _user, uint256 _tokenId) public view returns (bool) {
        require(_exists(_tokenId), "Token does not exist.");
        require(expireTime[_tokenId] > block.timestamp, "Pass is expired");

        return _user == ownerOf(_tokenId) ? true : false;
    }

    function getMetadata(uint256 _tokenId) internal view returns (string memory) {
        uint256 _currentexpiryTime = expireTime[_tokenId];
        string[7] memory parts;
        parts[0] = ', "attributes": [{"trait_type": "Type","value": "';
        parts[1] = _tokenId <= ogTokenEnd ? metadataParts[0] : metadataParts[1];
        parts[2] = '"}, {"trait_type": "Expiration","value": "';
        parts[3] = toString(_currentexpiryTime);
        parts[4] = '"}, {"trait_type": "Expired","value": "';
        parts[5] = _currentexpiryTime < block.timestamp ? "true" : "false";
        parts[6] = '"}], ';
        
        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]));
        return output;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenIdString = toString(tokenId);
        uint256 _currentexpiryTime = expireTime[tokenId];
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token.");

        string[3] memory parts;
        parts[0] = tokenId <= ogTokenEnd ? (_currentexpiryTime > block.timestamp ? metadataParts[2] : metadataParts[3]) : (_currentexpiryTime > block.timestamp ? metadataParts[4] : metadataParts[5]);
        parts[1] = tokenId <= ogTokenEnd ? metadataParts[6] : metadataParts[7];
        parts[2] = _currentexpiryTime > block.timestamp ? metadataParts[8] : metadataParts[9];

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "',parts[0],'',tokenIdString,'", "description": "',parts[1],'"', getMetadata(tokenId), '"image": "',parts[2],'',tokenIdString,'',metadataParts[10],'"}'))));
        json = string(abi.encodePacked('data:application/json;base64,', json));
        return json;
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
}

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