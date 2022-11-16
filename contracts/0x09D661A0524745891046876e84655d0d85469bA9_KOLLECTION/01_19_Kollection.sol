// SPDX-License-Identifier: MIT
// Creator: Serozense

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./OperatorFilterRegistry/DefaultOperatorFilterer.sol";

//                     ▄▄████
//                 ▄▄█▀▀ ▄██▀
//              ▄██▀    ▄██▀                                     ▄
//           ▄██▀      ███                                   ▄▄███▌
//         ▄█▀        ███                              ▄   ▄█▀ ███
//        ▀█▄▄▄     ▄███         ▄▄       ▄▄  ▄▄▄▄▄▄▄ ▐█ ▄█▀  ███
//                 ▄██▀ ▄▄▀▀▀▀▀▀███▀▀▀▀▀▀███▀▀        ██ ▀   ▐██    ▄
//                ███▌▄▄▄▄█▀▀   ██       ██          ██ ▄▄   ██▌ ▄▄▄█▀
//               ████▌     ▄██ ▐█▌  ▄▄█ ▐█▌▄███▌ ██ ▄██▐█▌  ████▀
//             ▄██▀███  ▀█▀▀██ ▐█ ▄█▀██ ██ ██▄█▌██████ ██  ▐████▄      ▄▄▄▄
//            ▄██▀  ███ ▀ ▀███ ██▄▀████ █▌ ▀▀▀▀ ▀  ▀▀▀ █   ██  ███         ▀▀█▄
//           ███     ▀██▄      █▌   ▀▀  █   ▄▄▄▄▄▀▀▀▀▀    ██    ▀██▄           ▀█▄
//          ███        ▀██▄             ▀                 █▌      ▀██▄          ▐██
//         ██▀            ▀██▄▄▄▀                                    ▀██▄       ██▀
//        ██                          THE KOLLECTION                     ▀▀███▀▀▀


    error IncorrectSignature();
    error MaxMinted();
    error CannotSetZeroAddress();
    error ItemAlreadyClaimed();

interface IContractBox {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract KOLLECTION is ERC1155, DefaultOperatorFilterer, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {

    using Address for address;
    using ECDSA for bytes32;
    using Strings for uint256;
    

    address public signingAddress;
    address public treasuryAddress;
    address public boxAddress;
    address public crossmint;


    uint256 private _currentTokenID = 0;
    mapping(uint256 => mapping(uint256 => bool)) private _claimed;

    constructor(
        address defaultTreasury,
        address signer,
        address box,
        string memory uri_
    ) ERC1155("") {
        _setURI(uri_);
        setTreasuryAddress(payable(defaultTreasury));
        setSigningAddress(signer);
        setBoxAddress(box);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    modifier requireCrossmint() {
        require(msg.sender == crossmint, "Crossmint only");
        _;
    }

    function create(address _initialOwner, uint256 _initialSupply) external onlyOwner returns(uint256) {
        uint256 _id = _getNextTokenID();
        _incrementTokenTypeId();

        _mint(_initialOwner, _id, _initialSupply, "");
        return _id;
    }

    function mint(bytes calldata signature, uint256 id, uint256 quantity, uint256 maxMintable) external payable callerIsUser {
        if(!verifySig(id, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(balanceOf(msg.sender, id) + quantity > maxMintable) revert MaxMinted();

        _mint(msg.sender, id, quantity, "");
    }

    function claim(uint256 id, uint256 box) external callerIsUser {
        address _owner = IContractBox(boxAddress).ownerOf(box);
        require(_owner == msg.sender, "You do not own this box");
        require(_currentTokenID + 1 > id, "Nonexistent token");
        if(_claimed[id][box]) revert ItemAlreadyClaimed();

        _mint(msg.sender, id, 1, "");
        _claimed[id][box] = true;
    }

    function claimed(uint256 id, uint256 box) external view returns(bool) {
        return _claimed[id][box];
    }

    function privateMint(bytes calldata signature, uint256 id, uint256 quantity, uint256 maxMintable) external payable {
        if(!verifySigPrivate(msg.sender, id, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(balanceOf(msg.sender, id) + quantity > maxMintable) revert MaxMinted();

        _mint(msg.sender, id, quantity, "");
    }

    function crossMint(bytes calldata signature, uint256 id, uint256 quantity, uint256 maxMintable, address to) external payable requireCrossmint {
        if(!verifySig(id, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(balanceOf(to, id) + quantity > maxMintable) revert MaxMinted();

        _mint(to, id, quantity, "");
    }

    function privateCrossMint(bytes calldata signature, uint256 id, uint256 quantity, uint256 maxMintable, address to) external payable requireCrossmint {
        if(!verifySigPrivate(to, id, maxMintable, msg.value/quantity, signature)) revert IncorrectSignature();
        if(balanceOf(to, id) + quantity > maxMintable) revert MaxMinted();

        _mint(to, id, quantity, "");
    }

    function airdrop(address to, uint256 id, uint256 quantity) external onlyOwner {
        _mint(to, id, quantity, "");
    }

    function setURI(string memory newUri) external onlyOwner {
        _setURI(newUri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function verifySig(uint256 id, uint256 maxMintable, uint256 valueSent, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(id, maxMintable, valueSent));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function verifySigPrivate(address sender, uint256 id, uint256 maxMintable, uint256 valueSent, bytes memory signature) internal view returns(bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(sender, id, maxMintable, valueSent));
        return signingAddress == messageHash.toEthSignedMessageHash().recover(signature);
    }

    function setSigningAddress(address newSigningAddress) public onlyOwner {
        if (newSigningAddress == address(0)) revert CannotSetZeroAddress();
        signingAddress = newSigningAddress;
    }

    function setBoxAddress(address newBoxAddress) public onlyOwner {
        if (newBoxAddress == address(0)) revert CannotSetZeroAddress();
        boxAddress = newBoxAddress;
    }

    function setCrossmint(address _crossmint) public onlyOwner {
        if (_crossmint == address(0)) revert CannotSetZeroAddress();
        crossmint = _crossmint;
    }

    function setTreasuryAddress(address payable newAddress) public onlyOwner {
        if (newAddress == address(0)) revert CannotSetZeroAddress();
        treasuryAddress = newAddress;
    }

    function withdraw() external onlyOwner {
        Address.sendValue(payable(treasuryAddress), address(this).balance);
    }

    function _getNextTokenID() private view returns (uint256) {
        return _currentTokenID + 1;
    }

    function _incrementTokenTypeId() private  {
        _currentTokenID++;
    }

    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        require(_currentTokenID + 1 > tokenId, "ERC1155Metadata: URI query for nonexistent token");
        return string(abi.encodePacked(ERC1155.uri(tokenId), tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal whenNotPaused override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data)
    public
    override
    onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

}