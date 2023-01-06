// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "default-nft-contract/contracts/libs/TokenSupplier/TokenUriSupplier.sol";
import "./interface/IMintValidator.sol";

contract CryptoNinjaChildrenSBT is ERC1155, Ownable, AccessControl, TokenUriSupplier {
    using Strings for uint256;

    bytes32 public constant ADMIN = "ADMIN";

    struct phaseStruct {
        bool onSale;
        address validator;
    }
    mapping(uint256 => phaseStruct) public phaseData;
    uint256 public nextPhaseId = 1; // phaseId == tokenId

    constructor() ERC1155("") {
        grantRole(ADMIN, msg.sender);
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract.");
        _;
    }

    modifier onlyTokenOwner(uint256 _id) {
        require(balanceOf(msg.sender, _id) > 0, "You don't have the token.");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "You are not authorized.");
        _;
    }

    modifier phaseExist(uint256 _phaseId) {
        require(0 < _phaseId && _phaseId < nextPhaseId, "not exist phaseId");
        _;
    }

    modifier onSale(uint256 _phaseId) {
        require(phaseData[_phaseId].onSale, "not sale");
        _;
    }

    function mint(uint256 _phaseId, uint256 _amount, uint256 _maxAmount, bytes32[] calldata _merkleProof) external payable
        callerIsUser
        phaseExist(_phaseId)
        onSale(_phaseId)
    {
        if (phaseData[_phaseId].validator != address(0)) {
            IMintValidator validator = IMintValidator(phaseData[_phaseId].validator);
            validator.validate(_amount, _maxAmount, msg.value, _merkleProof);
        }

        _mint(msg.sender, _phaseId, _amount, "");
    }

    function adminMint(uint256 _phaseId, address[] calldata _addresses, uint256[] memory _userMintAmounts) external
        phaseExist(_phaseId)
        onlyAdmin
    {
        require(_addresses.length > 0 && _userMintAmounts.length > 0, "At least one address and userMintAmount is required");
        require(_addresses.length == _userMintAmounts.length, "addresses and userMintAmounts length must be the same");

        for(uint256 i = 0; i < _addresses.length; ++i) {
            IMintValidator validator = IMintValidator(phaseData[_phaseId].validator);
            uint256 maxMintAmount = validator.maxAmount() - _mintedAmount(_phaseId, _addresses[i]);
            uint256 mintAmount = (_userMintAmounts[i] > maxMintAmount) ? maxMintAmount : _userMintAmounts[i];
            if (mintAmount > 0) {
                _mint(_addresses[i], _phaseId, mintAmount, "");
            }
        }
    }

    function burn(uint256 _id) external onlyTokenOwner(_id) {
        _burn(msg.sender, _id, 1);
    }

    function setPhaseData(uint256 _id, address _validator) public onlyAdmin {
        require(0 < _id && _id <= nextPhaseId, 'not exist or next');

        phaseData[_id].onSale = false;
        phaseData[_id].validator = _validator;
        if (_id == nextPhaseId) {
            ++nextPhaseId;
        }
    }

    function setOnSale(uint256 _phaseId, bool _onSale) external phaseExist(_phaseId) onlyAdmin {
        phaseData[_phaseId].onSale = _onSale;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns(bool)
    {
        return
            AccessControl.supportsInterface(_interfaceId) ||
            ERC1155.supportsInterface(_interfaceId);
    }

    function setApprovalForAll(address, bool) public virtual override {
        require(false, "This token is SBT, so this can not approve.");
    }

    function _beforeTokenTransfer(
        address,
        address from,
        address to,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) internal virtual override {
        require(
            from == address(0) || to == address(0),
            "This token is SBT, so this can not transfer."
        );
    }

    function uri(uint256 _tokenId) public view virtual override returns(string memory) {
        return TokenUriSupplier.tokenURI(_tokenId);
    }

    function _defaultTokenUri(uint256 tokenId)
        internal
        view
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    baseURI,
                    tokenId.toString(),
                    "_sbt",
                    baseExtension
                )
            );
    }

    function setBaseURI(string memory _baseURI) external override onlyAdmin {
        baseURI = _baseURI;
    }

    function setBaseExtension(string memory _baseExtension) external override onlyAdmin {
        baseExtension = _baseExtension;
    }

    function setExternalSupplier(address _value) external override onlyAdmin {
        externalSupplier = ITokenUriSupplier(_value);
    }

    // ==================================================================
    // Override Ownerble for fail safe
    // ==================================================================
    function renounceOwnership() public view override onlyOwner {
        revert("Can not renounceOwnership. In the absence of the Owner, the system will not be operational.");
    }

    //
    //withdraw section
    //
    address public withdrawAddress = 0x985D66886ea5797D221da4Cc2A5380A5849D08A2;
    function withdraw() external payable onlyAdmin {
        (bool os, ) = payable(withdrawAddress).call{value: address(this).balance}('');
        require(os);
    }

    function setWithdrawAddress(address _addr) external onlyAdmin {
        withdrawAddress = _addr;
    }

    function _mintedAmount(uint256 _phaseId, address _addr) internal view returns(uint256) {
        return balanceOf(_addr, _phaseId);
    }

    // for front
    function mintedAmount(uint256 _phaseId) public view phaseExist(_phaseId) returns(uint256) {
        return _mintedAmount(_phaseId, msg.sender);
    }

    // ==================================================================
    // operations
    // ==================================================================
    function grantRole(bytes32 _role, address _account)
        public
        override
        onlyOwner
    {
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account)
        public
        override
        onlyOwner
    {
        _revokeRole(_role, _account);
    }
}