// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract CollectionInterface {
    function mintTransfer(address to) public virtual returns(uint256);
}

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract Vialz is ERC1155, ERC1155Burnable, IERC2981, Ownable, ReentrancyGuard {

    struct listParameters {
        bytes32 _root;
        uint256 _price;
        uint16 _available;
    }

    enum Stage {
        None,
        Pre,
        Wl,
        Pub
    }

    uint256 public constant MAX_SUPPLY = 9999;
    Stage public currentStageId = Stage.None;
    uint256 public tokenId = 0;
    uint256 public amountMinted = 0;
    bool public migrationStarted = false;
    uint256 public maxAmountPerTransactionPublic = 10;
    string public name = "VOLTZ Avatars MintVialz";
    string public symbol = "VIALZ";
    string public constant _baseURI = "ipfs://QmUjj4333BXDRi6bJJXF6cJPgSzjHp1xeWHCQtyxYiC5g8";

    address private creator;
    address private collectionContractAddress;
    address private royaltiesAddress = 0x3aC8d44a7A6579145f4B83accbfbbD6a497509a2;
    address private withdrawAddress = 0xEb0FC5eDb13D0b42f7555AE181a173F592284F3f;
    uint256 private royaltiesPercentage = 75;

    mapping(address => uint256) public claimedExplorerTokens;
    mapping(address => uint256) public claimedGrantedTokens;
    mapping(address => uint256) public claimedPreSaleTokens;
    mapping(address => uint256) public claimedPublicTokens;
    mapping(uint256 => listParameters) private listsData;

    constructor(address payable owner) ERC1155(_baseURI) {
        require(owner != address(0), 'Zero address not allowed');

        listsData[1] = listParameters(0x9979f64ba24c592bd32b9ad17c6408d6e0b412abaa9df6fdc1a32d9b6bbb6ec9, 0.05 ether, 4444);
        listsData[2] = listParameters(0x9b3e0fda6acce59669bda2c3475b3e04e6538ceccfa5e7bc3ceed8157b0eb16e, 0.05 ether, 2200);
        listsData[3] = listParameters(0xffcf42a4f71cca202bbb8332b98c87af8e941b7b37e13a906660201351702d17, 0 ether, 3355);
        listsData[4] = listParameters(0x0, 0 ether, 0);
    }

    function totalSupply() public pure returns (uint256) {
        return MAX_SUPPLY;
    }

    function contractURI() public pure returns (string memory) {
        return _baseURI;
    }

    function setMerkleRoot(bytes32 _merkleRoot, uint256 _listId) public onlyOwner returns (bool success) {
        listsData[_listId]._root = _merkleRoot;
        return true;
    }

    function setCollectionContract(address contractAddress) public onlyOwner returns (bool success) {
        require(contractAddress != address(0), 'Zero address not allowed');
        collectionContractAddress = contractAddress;
        return true;
    }

    function setStage(uint8 stageId) public onlyOwner returns (bool success) {
        currentStageId = Stage(stageId);
        return true;
    }

    function setPublicPrice(uint256 price) public onlyOwner returns (bool success) {
        listsData[4]._price = price;
        return true;
    }

    function toggleMigration() public onlyOwner returns (bool success) {
        migrationStarted = !migrationStarted;
        return true;
    }

    modifier verifyProof(bytes32[] calldata _merkleProof, uint _maxAmount, uint256 _listId) {
        bytes32 leaf = encodeLeaf(msg.sender, _maxAmount, _listId);
        require((MerkleProof.verify(_merkleProof, listsData[_listId]._root, leaf) || _listId == 4), "Invalid proof of inclusion.");
	    _;
    }

    function mintVial(bytes32[] calldata _merkleProof, uint _amount, uint _maxAmount, uint256 _listId) public payable nonReentrant() verifyProof(_merkleProof, _maxAmount, _listId) returns(uint256) {
        require((amountMinted + _amount) <= MAX_SUPPLY, "Max supply reached");
        uint _price = _amount * listsData[_listId]._price;
        if (currentStageId == Stage.Pre) {
            if (_listId == 1) {
                require(claimedExplorerTokens[msg.sender] <= _maxAmount, "Address already claimed all his NFTs");
                require(claimedExplorerTokens[msg.sender] + _amount <= _maxAmount, "Maximum amount exceeded");
                require(listsData[1]._available != 0, "Explorer Tokens are sold out!");
                require(msg.value >= _price, "Insufficient funds to mint");

                for (uint i = 0; i < _amount; i++) {
                    tokenId++;
                    _mint(msg.sender, tokenId, 1, "");
                    amountMinted++;
                    claimedExplorerTokens[msg.sender] += 1;
                    listsData[1]._available -= 1;
                }

                if (msg.value > _price) {
                    uint256 change = msg.value - _price;
                    payable(msg.sender).transfer(change);
                }
                return tokenId;
            }
            else if (_listId == 2) {
                require(claimedGrantedTokens[msg.sender] <= _maxAmount, "Address already claimed all his NFTs");
                require(claimedGrantedTokens[msg.sender] + _amount <= _maxAmount, "Maximum amount exceeded");
                require(listsData[2]._available != 0, "Helmet Tokens are sold out!");
                require(msg.value >= _price, "Insufficient funds to mint");

                for (uint i = 0; i < _amount; i++) {
                    tokenId++;
                    _mint(msg.sender, tokenId, 1, "");
                    amountMinted++;
                    claimedGrantedTokens[msg.sender] += 1;
                    listsData[2]._available -= 1;
                }

                if (msg.value > _price) {
                    uint256 change = msg.value - _price;
                    payable(msg.sender).transfer(change);
                }

                return tokenId;
            }
            else {
                revert("List is not authorized at this stage");
            }
        }
        else if (currentStageId == Stage.Wl) {
            if (_listId == 3) {
                require(claimedPreSaleTokens[msg.sender] <= _maxAmount, "Address already claimed all his NFTs");
                require(claimedPreSaleTokens[msg.sender] + _amount <= _maxAmount, "Maximum amount exceeded");
                require(listsData[3]._available != 0, "PreSale Tokens are sold out!");

                for (uint i = 0; i < _amount; i++) {
                    tokenId++;
                    _mint(msg.sender, tokenId, 1, "");
                    amountMinted++;
                    claimedPreSaleTokens[msg.sender] += 1;
                    listsData[3]._available -= 1;
                }

                return tokenId;
            }
            else {
                revert("List is not authorized at this stage");
            }
        }
        else if (currentStageId == Stage.Pub) {
            if (_listId == 4) {
                require(MAX_SUPPLY - amountMinted > 0, "Public Tokens are sold out!");
                require(msg.value >= _price, "Insufficient funds to mint");
                require(_amount <= maxAmountPerTransactionPublic, "Maximum amount per transaction exceeded");

                for (uint i = 0; i < _amount; i++) {
                    tokenId++;
                    _mint(msg.sender, tokenId, 1, "");
                    amountMinted++;
                    claimedPublicTokens[msg.sender] += 1;
                }

                if (msg.value > _price) {
                    uint256 change = msg.value - _price;
                    payable(msg.sender).transfer(change);
                }
                return tokenId;
            }
            else {
                revert("List is not authorized at this stage");
            }
        }
        else {
            revert("Transaction is not authorized at this stage");
        }

    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (ERC1155, IERC165) returns (bool) {
        return (interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids,  amounts, data);
    }

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0), "Royalties: new recipient is the zero address");
        royaltiesAddress = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view override returns (address receiver, uint256 royaltyAmount) {
        return (royaltiesAddress, (_salePrice * royaltiesPercentage) / 1000);
    }

    function migrateToken(uint256 id) public returns(uint256) {
        require(migrationStarted == true, "Migration has not started");
        require(balanceOf(msg.sender, id) > 0, "You do not own this token");
        burn(msg.sender, id, 1);
        CollectionInterface collectionContract = CollectionInterface(collectionContractAddress);
        uint256 mintedId = collectionContract.mintTransfer(msg.sender);
        return mintedId;
    }

    function uintToStr(uint256 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            while (x > 0) {
                str = string(abi.encodePacked(uint8(x % 10 + 48), str));
                x /= 10;
            }
            return str;
        }
        return "0";
    }

    function addressToAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function encodeLeaf(address _address, uint256 _maxAmount, uint256 _listId) internal pure returns(bytes32) {
        string memory prefix = "0x";
        string memory space = " ";

        bytes memory _ba = bytes(prefix);
        bytes memory _bb = bytes(addressToAsciiString(_address));
        bytes memory _bc = bytes(space);
        bytes memory _bd = bytes(uintToStr(_maxAmount));
        bytes memory _be = bytes(space);
        bytes memory _bf = bytes(uintToStr(_listId));
        string memory abcdef = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length + _bf.length);
        bytes memory babcdef = bytes(abcdef);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcdef[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) babcdef[k++] = _bb[i];
        for (uint i = 0; i < _bc.length; i++) babcdef[k++] = _bc[i];
        for (uint i = 0; i < _bd.length; i++) babcdef[k++] = _bd[i];
        for (uint i = 0; i < _be.length; i++) babcdef[k++] = _be[i];
        for (uint i = 0; i < _bf.length; i++) babcdef[k++] = _bf[i];
        return bytes32(keccak256(babcdef));
    }

    function withdraw() public onlyOwner returns(bool) {
        payable(withdrawAddress).transfer(address(this).balance);
        return true;
    }

    function renounceOwnership() public view override onlyOwner {
        revert("Cannot renounce ownership");
    }

    function getAvailableTokensByList(uint256 _listId) public view returns(uint256) {
        return listsData[_listId]._available;
    }

}