// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

import "./Peacefall.sol";

contract PeacefallPotion
    is ERC721, ERC721Enumerable, ERC721Pausable, ERC721Holder, ERC721Burnable, AccessControl {

    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // Access Control Roles

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant APOTHECARY_ROLE = keccak256("APOTHECARY_ROLE");
    bytes32 public constant FINANCIER_ROLE = keccak256("FINANCIER_ROLE");
    bytes32 public constant PAYOUT_ROLE = keccak256("PAYOUT_ROLE");

    constructor() ERC721("PeacefallPotion", "PFP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(APOTHECARY_ROLE, msg.sender);
        _grantRole(FINANCIER_ROLE, msg.sender);
        _setRoleAdmin(PAYOUT_ROLE, FINANCIER_ROLE);
        _pause();
    }


    // URI settings

    string private _baseURIValue;

    function _baseURI() internal view override returns (string memory) {
        return _baseURIValue;
    }

    function setBaseURI(string memory uri) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _baseURIValue = uri;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked(super.tokenURI(tokenId), ".json"));
    }

    // Contract Pause

    function pause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    modifier adminCanIgnorePause {
        bool startedPaused = paused();
        bool senderIsAdmin = hasRole(DEFAULT_ADMIN_ROLE, msg.sender);
        if(startedPaused && senderIsAdmin){
            _unpause();
        }
        _;
        if(startedPaused && senderIsAdmin){
            _pause();
        }
    }

    // Minting

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    uint256 public MINT_PRICE = 0 ether;
    bool public publicMinting = false;

    function setPublicMinting(bool state) public onlyRole(MINTER_ROLE) {
        publicMinting = state;
    }

    function setMintPrice(uint256 mintPrice) public onlyRole(FINANCIER_ROLE) {
        MINT_PRICE = mintPrice;
    }

    function publicMint(address to) public payable adminCanIgnorePause {
        require(publicMinting || hasRole(MINTER_ROLE, msg.sender), "Public minting is disabled!");
        require((msg.value >= MINT_PRICE) || hasRole(MINTER_ROLE, msg.sender), "Insufficient ETH!");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }


    // Peacefall contract

    Peacefall public peacefall;

    function setPeacefall(address contractAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        peacefall = Peacefall(contractAddress);
    }


    // Potion Consumption

    uint256 public USE_PRICE = 0 ether;
    mapping(uint256 => bytes32) potionReceipts;

    function setUsePrice(uint256 usePrice) public onlyRole(FINANCIER_ROLE){
        USE_PRICE = usePrice;
    }

    function usePotion(uint256 potionId, uint256[] calldata consumedWarriorIds) public payable {
        require((msg.value >= USE_PRICE) || hasRole(APOTHECARY_ROLE, msg.sender), "Insufficient ETH!");
        potionReceipts[potionId] = keccak256(abi.encodePacked(msg.sender, consumedWarriorIds));
        safeTransferFrom(msg.sender, address(this), potionId);
        for(uint consumedIndex=0; consumedIndex < consumedWarriorIds.length; consumedIndex++){
            peacefall.safeTransferFrom(msg.sender, address(this), consumedWarriorIds[consumedIndex]);
        }
    }

    function revertPotion(uint256 potionId, uint256[] calldata consumedWarriorIds, address to) public onlyRole(APOTHECARY_ROLE) {
        require(
            keccak256(abi.encodePacked(to, consumedWarriorIds)) == potionReceipts[potionId], "Invalid potion receipt!");
        delete potionReceipts[potionId];
        _safeTransfer(address(this), to, potionId, "");
        for(uint consumedIndex=0; consumedIndex < consumedWarriorIds.length; consumedIndex++){
            peacefall.safeTransferFrom(address(this), to, consumedWarriorIds[consumedIndex]);
        }
    }

    function finalizePotion(uint256 potionId, uint256[] calldata consumedWarriorIds, address from) public onlyRole(APOTHECARY_ROLE) {
        require(
            keccak256(abi.encodePacked(from, consumedWarriorIds)) == potionReceipts[potionId], "Invalid potion receipt!");
        _burn(potionId);
        delete potionReceipts[potionId];
        for(uint consumedIndex=0; consumedIndex < consumedWarriorIds.length; consumedIndex++){
            // Peacefall doesn't implement burning natively, so we send to a burner address
            peacefall.safeTransferFrom(address(this), address(0x0000dEaD), consumedWarriorIds[consumedIndex]);
        }

    }


    // Withdrawing Ether

    function payEther(address to, uint256 amount) external onlyRole(FINANCIER_ROLE) {
        require(hasRole(PAYOUT_ROLE, to), "Invalid payout address");
        uint256 balance = address(this).balance;
        uint256 transferAmount = balance >= amount? amount : balance;
        payable(to).call{value: transferAmount}("");
    }
}