// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../interfaces/IParcelInterface.sol";
import "./ERC721Base.sol";
import "../Municipality.sol";

contract StandardParcelNFT is
    ERC721Base,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 constant PARCEL_TYPE = 10;

    address public municipalityAddress;
    address public minerPublicBuilding;
    mapping(uint256 => bool) private upgradedParcelsMapping;

    uint8 private constant PARCEL_LAND_TYPE_NEXT_TO_OCEAN = 10;
    uint8 private constant PARCEL_LAND_TYPE_NEAR_OCEAN = 20;
    uint8 private constant PARCEL_LAND_TYPE_INLAND = 30;

    event TransferActivationSet(bool indexed transferActivation);
    event MaxSupplySet(uint256 indexed amount);
    event MunicipalityAddressSet(address indexed municipalityAddress);
    event MinerPublicBuildingSet(address indexed minerPublicBuildingAddress);
    event StandardParcelUpgraded(address indexed user, uint256 indexed parcelId);

    modifier onlyAuthorizedContracts() {
        require(minerPublicBuilding == msg.sender || msg.sender == municipalityAddress, "MinerNFT: Only authorized contracts can call this function");
        _;
    }

    modifier onlyUnlockedToken(uint256 _tokenId) override {
        require(Municipality(payable(municipalityAddress)).isTokenLocked(address(this), _tokenId) == false, "StandardParcel: This parcel is locked and can not be transfered");
        _;
    }

    // @notice Proxy SC support - initialize internal state
    function initialize(string memory _tokenBaseURI, address _municipalityAddress, uint256 _maxSupply)
        external
        initializer
    {
        __Ownable_init();
        __ReentrancyGuard_init();
        municipalityAddress = _municipalityAddress;
        _name = "StandardParcel";
        _symbol = "SP";
        _baseURI = _tokenBaseURI;
        _setMaxSupply(_maxSupply);
    }

    function setTransferActivation(bool _transferActivation) public onlyOwner {
        _setTransferActivation(_transferActivation);
        emit TransferActivationSet(_transferActivation);
    }

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        _setMaxSupply(_maxSupply);
        emit MaxSupplySet(_maxSupply);
    }

    function setMunicipalityAddress(address _municipalityAddress) external onlyOwner {
        municipalityAddress = _municipalityAddress;
        emit MunicipalityAddressSet(municipalityAddress);
    }

    function setMinerPublicBuildingAddress(address _minerPublicBuilding) external onlyOwner {
        minerPublicBuilding = _minerPublicBuilding;
        emit MinerPublicBuildingSet(minerPublicBuilding);
    }

    /// @notice IParcelInterface functions
    function mint(address _user, uint256 _x, uint256 _y, uint256 _lt) public onlyAuthorizedContracts returns (uint256) {
        uint256 parcelId = _getParcelId(_x, _y, _lt);
        require(!_exists(parcelId), "StandardParcelNFT: Parcel already exists as a standard parcel");
        _mintFor(parcelId, _user);
        return parcelId;
    }

    function upgradeParcel(uint256 tokenId) external onlyAuthorizedContracts  {
        upgradedParcelsMapping[tokenId] = true;
        emit StandardParcelUpgraded(msg.sender, tokenId);
    }

    function upgradeParcels(uint256[] memory tokenIds) external onlyAuthorizedContracts  {
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            upgradedParcelsMapping[tokenIds[i]] = true;
            emit StandardParcelUpgraded(msg.sender, tokenIds[i]);
        }
    }

    function parcelExists(uint256 _x, uint256 _y, uint256 _lt) external view returns(bool) {
        return _parcelExists(_x, _y, _lt);
    }

    function getParcelId(uint256 _x, uint256 _y, uint256 _lt) external pure returns (uint256) {
        return _getParcelId(_x, _y, _lt);
    }

    function isParcelUpgraded(uint256 tokenId) external view returns (bool) {
        return upgradedParcelsMapping[tokenId];
    }

    function getParcelInfo(uint256 token)  public pure returns (uint256, uint256, uint256, uint256) { //private pure
        uint256 x = token & 65535;
        uint256 y = (token >> 16) & 65535;
        uint256 pt = (token >> 32) & 255;
        uint256 lt = token >> 40;
        return (x, y, pt, lt);
    }

    function getUpgradedParcelIds(address _user) external view returns(uint256[] memory) {
        uint256[] memory tokensOf;
        tokensOf = this.tokensOf(_user);
        uint256 j;
        uint256[] memory newTokensOf = new uint[](tokensOf.length); 
       for (uint256 i = 0; i < tokensOf.length; i++) {
            if (upgradedParcelsMapping[tokensOf[i]]) {
                newTokensOf[j] = tokensOf[i];
                j++;
            }
        }
        uint256[] memory upgradedParcesIds = new uint256[](j);
       for (uint256 i = 0; i < j; i++) {
            upgradedParcesIds[i] = newTokensOf[i];
        }
       return upgradedParcesIds;
    }

    // Private interface
    function _getParcelId(uint256 _x, uint256 _y, uint256 _lt) private pure returns (uint256) {
        uint256 token = _lt;
        token = (token << 8) | PARCEL_TYPE;
        token = (token << 16) | _y;
        token = (token << 16) | _x;
        return token;
    }

    function _parcelExists(uint256 _x, uint256 _y, uint256 _lt) private view returns(bool) {
        uint256 parcelId = _getParcelId(_x, _y, _lt);
        return _exists(parcelId);
    }

    function mintParcels(address _user, Municipality.Parcel[] calldata parcels) external onlyAuthorizedContracts returns(uint256[] memory) {
        uint256[] memory parcelIds = new uint256[](parcels.length);
        for (uint256 i = 0; i < parcels.length; ++i) {
            Municipality.Parcel memory parcel = parcels[i];
            require(
                parcel.parcelLandType == PARCEL_LAND_TYPE_NEXT_TO_OCEAN ||
                    parcel.parcelLandType == PARCEL_LAND_TYPE_NEAR_OCEAN ||
                    parcel.parcelLandType == PARCEL_LAND_TYPE_INLAND,
                "Municipality: Invalid parcel land type"
            );
            uint256 parcelId = mint(
                _user,
                parcel.x,
                parcel.y,
                parcel.parcelLandType
            );
            parcelIds[i] = parcelId;
        }
        return parcelIds;
    }
}