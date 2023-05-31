//SPDX-License-Identifier: MIT
/** 
  o8boooo 888      88888888 8888PPPp, 8888PPPp, 888   88 
  88booop 888      888  888 8888    8 8888    8 888ooo88 
  88b     888      888  888 8888PPPP' 8888PPPP'       88 
  88P     888PPPPP 888oo888 888P      888P      PPPPPP8P 

                   By zensein#5412
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

error collectionSaleNotActive();
error alreadyMinted();
error maxSupplyReached();
error invalidCollection();
error directMintDisallowed();

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract FloppyNftErc1155 is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    string private constant SIG_WORD = "FLOPPY_NFT";
    address private proxyRegistryAddress;
    address private constant SIGNER =
        0x3f22e08Ca09BF365F9Fe3aD69fA4f213444E1062;

    mapping(uint256 => Collection) public collections;

    struct Collection {
        bool active;
        uint32 maxSupply;
        mapping(address => bool) mintList;
    }

    constructor(address _proxyRegistryAddress)
        ERC1155(
            "https://floppynft.mypinata.cloud/ipfs/QmZo2WTSJEj8wbvji8PykSmvv1RkpEdEhi1JmnPwppDzGv/{id}.json"
        )
    {
        collections[0].maxSupply = 999;
        collections[1].maxSupply = 799;
        collections[2].maxSupply = 599;
        collections[3].maxSupply = 399;
        collections[4].maxSupply = 299;
        collections[5].maxSupply = 299;
        proxyRegistryAddress = _proxyRegistryAddress;
    }

    /** 
        MODIFIERS 
    */

    modifier isMintLive(uint256 collectionId) {
        if (!collections[collectionId].active) revert collectionSaleNotActive();
        _;
    }

    modifier isValidCollectionId(uint256 collectionId) {
        if (collectionId > 5) revert invalidCollection();
        _;
    }

    /**
        MAIN FUNCTIONS
    */

    function matchAddresSigner(bytes memory signature, uint256 collectionId)
        private
        view
        returns (bool)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(msg.sender, SIG_WORD, collectionId))
            )
        );
        return SIGNER == hash.recover(signature);
    }

    function mint(uint256 collectionId, bytes memory signature)
        external
        isValidCollectionId(collectionId)
        isMintLive(collectionId)
    {
        if (!matchAddresSigner(signature, collectionId))
            revert directMintDisallowed();
        Collection storage collection = collections[collectionId];
        if (!collection.active) revert collectionSaleNotActive();
        if (collection.mintList[msg.sender]) revert alreadyMinted();
        if (totalSupply(collectionId) > collection.maxSupply)
            revert maxSupplyReached();

        collection.mintList[msg.sender] = true;
        _mint(msg.sender, collectionId, 1, "");
    }

    /**
        OPENSEA WHITELIST PROXY
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool isOperator)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == _operator) {
            return true;
        }

        return ERC1155.isApprovedForAll(_owner, _operator);
    }

    /** 
        ONLY OWNER OPERATIONS
    */

    function toggleCollectionSale(uint256 collectionId)
        external
        onlyOwner
        isValidCollectionId(collectionId)
    {
        collections[collectionId].active = !collections[collectionId].active;
    }

    function setURI(string calldata newUri) external onlyOwner {
        _setURI(newUri);
    }
}