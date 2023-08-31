// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./IERC6551Registry.sol";

contract MadMemberPassDressUpSbt is ERC1155, AccessControl, Ownable, Pausable {
    using Strings for uint256;
    using ECDSA for bytes32;

    // Manage
    bytes32 public constant ADMIN = "ADMIN";
    address public withdrawAddress;

    // ERC6551
    IERC6551Registry public registryContract = IERC6551Registry(0x02101dfB77FDE026414827Fdc604ddAF224F0921);
    address public implementation = 0x2D25602551487C3f3354dD80D76D54383A243358;
    uint256 public chainId = 1;
    address public tokenContract = 0x3F2B98BdE2DF37aB83c79696A3d3d691355c4fF8;
    uint256 public salt = 0;

    // Metadata
    string public name = "MadMemberPass DressUp SBT";
    string public symbol = "MMPDU";
    string public baseURI;
    string public baseExtension = ".json";

    // Mint
    uint256 public nonce = 0;
    address private signer;
    mapping(uint256 => uint256) public mintCosts;
    mapping(uint256 => uint256) public totalSupply;

    // Modifier
    modifier doNotHave(uint256 _mmpTokenId, uint256 _tokenId) {
        require(balanceOf(getAddress(_mmpTokenId), _tokenId) == 0, "Already Have");
        _;
    }
    modifier enoughEth(uint256 _tokenId) {
        require(mintCosts[_tokenId] > 0, "Invalid TokenId");
        require(msg.value >= mintCosts[_tokenId], 'Not Enough Eth');
        _;
    }
    modifier isValidSignature (uint256 _mmpTokenId, uint256 _tokenId, bytes calldata _signature) {
        address recoveredAddress = keccak256(
            abi.encodePacked(
                msg.sender,
                _mmpTokenId,
                _tokenId,
                nonce
            )
        ).toEthSignedMessageHash().recover(_signature);
        require(recoveredAddress == signer, "Invalid Signature");
        _;
    }

    // Constructor
    constructor() ERC1155("") {
        withdrawAddress = msg.sender;
        _grantRole(ADMIN, msg.sender);
    }

    // Mint
    function claim(uint256 _mmpTokenId, uint256 _tokenId, bytes calldata _signature) external
        whenNotPaused()
        isValidSignature(_mmpTokenId, _tokenId, _signature)
    {
        nonce++;
        _mintCommon(_mmpTokenId, _tokenId);
    }
    function mint(uint256 _mmpTokenId, uint256 _tokenId) external payable
        whenNotPaused()
        enoughEth(_tokenId)
    {
        _mintCommon(_mmpTokenId, _tokenId);
    }
    function airdrip(uint256 _mmpTokenId, uint256 _tokenId) external onlyRole(ADMIN)
    {
        _mintCommon(_mmpTokenId, _tokenId);
    }
    function _mintCommon(uint256 _mmpTokenId, uint256 _tokenId) private
        doNotHave(_mmpTokenId, _tokenId)
    {
        _mint(getAddress(_mmpTokenId), _tokenId, 1, "");
        totalSupply[_tokenId]++;
    }
    function withdraw() external payable onlyRole(ADMIN) {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}("");
        require(os);
    }

    // Getter
    function uri(uint256 tokenId) public view virtual override returns (string memory) {
        return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
    }
    function getAddress(uint256 _mmpTokenId) public view returns (address) {
        return registryContract.account(implementation, chainId, tokenContract, _mmpTokenId, salt);
    }

    // Setter
    function setBaseURI(string memory _value) external onlyRole(ADMIN) {
        baseURI = _value;
    }
    function setBaseExtension(string memory _value) external onlyRole(ADMIN) {
        baseExtension = _value;
    }
    function resetBaseExtension() external onlyRole(ADMIN) {
        baseExtension = "";
    }
    function setWithdrawAddress(address _value) external onlyRole(ADMIN) {
        withdrawAddress = _value;
    }
    function setSigner(address _value) external onlyRole(ADMIN) {
        signer = _value;
    }
    function setMintCosts(uint256[] calldata _tokenIds, uint256 _mintCost) external onlyRole(ADMIN) {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            mintCosts[_tokenIds[i]] = _mintCost;
        }
    }
    function setRegistryContract(address _value) external onlyRole(ADMIN) {
        registryContract = IERC6551Registry(_value);
    }
    function setERC6551Info(address _implementation, uint256 _chainId, address _tokenContract, uint256 _salt) external onlyRole(ADMIN){
        implementation = _implementation;
        chainId = _chainId;
        tokenContract = _tokenContract;
        salt = _salt;
    }

    // Pausable
    function pause() public onlyRole(ADMIN) {
        _pause();
    }
    function unpause() public onlyRole(ADMIN) {
        _unpause();
    }

    // AccessControl
    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }
    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // SBT
    function setApprovalForAll(address, bool) public virtual override {
        revert("This token is SBT.");
    }
    function _beforeTokenTransfer(address, address from, address to, uint256[] memory ids, uint256[] memory, bytes memory) internal virtual override {
        for (uint256 i = 0; i < ids.length; i++) {
            require(from == address(0) || to == address(0), "This token is SBT.");
        }
    }

    // interface
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return
            AccessControl.supportsInterface(interfaceId) ||
            ERC1155.supportsInterface(interfaceId);
    }
}