//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../interfaces/IOriConfig.sol";
import "../interfaces/ITokenActionable.sol";
import "../venders/EIP712.sol";
import "./NFTMetadataURI.sol";
import "./ConsiderationConstants.sol";
import "./ConfigHelper.sol";

abstract contract NFTCreator is EIP712, NFTMetadataURI, ITokenActionable {
    using ConfigHelper for IOriConfig;

    mapping(bytes32 => bool) private _used;
    address private _originToken;
    address private _creator;

    function _initNFT(address origin, address creator_) internal {
        _originToken = origin;
        _creator = creator_;
        init("ORI", "1");
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "not owner");
        _;
    }

    modifier onlyOperator() {
        require(operator() == msg.sender, "not operator");
        _;
    }

    /*
     * @dev Returns this token derivative deployer.
     */
    function creator() external view override returns (address) {
        return _creator;
    }

    /**
     * @dev Returns the editor of the current collection on Opensea.
     * this editor will be configured in the `IOriConfig` contract.
     */
    function owner() public view override returns (address) {
        return IOriConfig(CONFIG).nftEditor();
    }

    /*
     * @dev Returns the derivative slave NFT contract address.
     */
    function originToken() external view override returns (address) {
        return _originToken;
    }

    /*
     * @dev Returns the NFT operator address(ITokenOperator).
     * Only operator can mint or burn derivative NFT.
     */
    function operator() public view override returns (address) {
        return IOriConfig(CONFIG).operator();
    }

    function setBaseURI(string calldata newuri) external onlyOwner {
        _setBaseURI(newuri);
    }

    /**
     * @dev See {DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _useSign(
        address who,
        bytes32 dataHash,
        bytes memory signature
    ) internal {
        bytes32 hash = _hashTypedDataV4(dataHash);
        require(!_used[hash], "double spend");
        address signer = ECDSA.recover(hash, signature);
        require(signer == who, "invalid signature");

        _used[hash] = true;
    }
}