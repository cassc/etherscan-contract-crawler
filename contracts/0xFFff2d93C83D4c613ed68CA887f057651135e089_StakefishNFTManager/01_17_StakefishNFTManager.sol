// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "ReentrancyGuard.sol";
import "ERC721Enumerable.sol";

import "IStakefishNFTManager.sol";
import "IStakefishValidatorFactory.sol";
import "IStakefishValidator.sol";
import "IStakefishValidatorWallet.sol";

/// @title StakefishNFTManager implementation
/// @notice Extends ERC721, mints and burns NFT representing validators
contract StakefishNFTManager is IStakefishNFTManager, ERC721Enumerable, ReentrancyGuard {
    address public immutable override factory;

    /// @dev deployed validator contract => tokenId
    mapping(address => uint256) private _validatorToToken;

    /// @dev tokenId => deployed validator contract
    mapping(uint256 => address) private _tokenToValidator;

    /// @dev The ID of the next token that will be minted.
    uint256 internal _nextId = 1;

    modifier isAuthorizedForToken(uint256 tokenId) {
        require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved');
        _;
    }

    modifier isNFTOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, 'Not nft owner');
        _;
    }

    constructor(address factory_) ERC721("stakefish validator", "SF-VLDR") {
        require(factory_ != address(0), "missing factory");
        factory = factory_;
    }

    /// PUBLIC WRITE FUNCTIONS
    function mint(uint256 validatorCount) external override payable nonReentrant {
        require(validatorCount > 0, "wrong value: at least 1 validator must be minted");
        require(validatorCount <= IStakefishValidatorFactory(factory).maxValidatorsPerTransaction(), "wrong value: validatorCount exceeds factory limit per transaction");
        require(msg.value == validatorCount * 32 ether, "wrong value: must be 32 ETH per validator");
        for(uint256 i=0; i < validatorCount; i++) {
            _mintOne();
        }
    }

    function verifyAndBurn(address newManager, uint256 tokenId) external override isAuthorizedForToken(tokenId) nonReentrant {
        require(newManager != address(this), "new NFTManager cannot be the same as the current NFTManager");
        require(IStakefishNFTManager(newManager).validatorOwner( _tokenToValidator[tokenId]) == ownerOf(tokenId), "owner on new NFTManager not confirmed");
        address validatorAddress = _tokenToValidator[tokenId];

        _burn(tokenId);
        _validatorToToken[validatorAddress] = 0;
        _tokenToValidator[tokenId] = address(0);

        require(IStakefishValidatorWallet(payable(validatorAddress)).getNFTManager() == newManager, "validator not changed to new nft manager");
        emit StakefishBurnedWithContract(tokenId, validatorAddress, msg.sender);
    }

    function multicallStatic(uint256[] calldata tokenIds, bytes[] calldata data) external view override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            address validatorAddr = _tokenToValidator[tokenIds[i]];
            require(validatorAddr != address(0), "multicall: address is null");
            results[i] = Address.functionStaticCall(validatorAddr, data[i]);
        }
        return results;
    }

    function multicall(uint256[] calldata tokenIds, bytes[] calldata data) external override returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            address validatorAddr = _tokenToValidator[tokenIds[i]];
            require(validatorAddr != address(0), "multicall: address is null");
            require(ownerOf(tokenIds[i]) == msg.sender, "only nft owner allowed");
            results[i] = Address.functionCall(validatorAddr, data[i]);

            burnIfNecessary(tokenIds[i]);
        }
        return results;
    }

    function withdraw(uint256 tokenId) external override isNFTOwner(tokenId) nonReentrant {
        address validatorAddr = validatorForTokenId(tokenId);
        IStakefishValidator(validatorAddr).withdraw();
        burnIfNecessary(tokenId);
    }

    function claim(address, uint256) external virtual override {
        require(false, "migration is unsupported");
    }

    function burnIfNecessary(uint256 tokenId) internal {
        address validatorAddr = validatorForTokenId(tokenId);

        // must be burned by migrate()
        if(validatorAddr == address(0)) {
            return;
        }

        IStakefishValidator.StateChange memory lastState = IStakefishValidator(validatorAddr).lastStateChange();
        if(lastState.state == IStakefishValidator.State.Burnable) {
            _burn(tokenId);
            _validatorToToken[validatorAddr] = 0;
            _tokenToValidator[tokenId] = address(0);

            emit StakefishBurnedWithContract(tokenId, validatorAddr, msg.sender);
        }
    }

    /// PUBLIC READ FUNCTIONS
    function validatorOwner(address validator) external override view returns (address) {
        return ownerOf(_validatorToToken[validator]);
    }

    function validatorForTokenId(uint256 tokenId) public override view returns (address) {
        return _tokenToValidator[tokenId];
    }

    function tokenForValidatorAddr(address validator) external override view returns (uint256) {
        return _validatorToToken[validator];
    }

    function computeAddress(uint256 tokenId) external override view returns (address) {
        return IStakefishValidatorFactory(factory).computeAddress(address(this), tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, IERC721Metadata) returns (string memory)
    {
        IStakefishValidator validator = IStakefishValidator(validatorForTokenId(tokenId));
        return validator.render();
    }

    /// PRIVATE WRITE FUNCTIONS
    function _updateTokenId(uint256 tokenId, address validatorAddr) internal {
        require(_validatorToToken[validatorAddr] == 0, "mint: must be empty tokenId");
        _validatorToToken[validatorAddr] = tokenId;
        _tokenToValidator[tokenId] = validatorAddr;
    }

    function _mintOne() internal {
        uint256 tokenId = _nextId++;
        address validatorAddr = IStakefishValidatorFactory(factory).createValidator{value: 32 ether}(tokenId);
        _mint(msg.sender, tokenId);
        _updateTokenId(tokenId, validatorAddr);
        emit StakefishMintedWithContract(tokenId, validatorAddr, msg.sender);
    }

}