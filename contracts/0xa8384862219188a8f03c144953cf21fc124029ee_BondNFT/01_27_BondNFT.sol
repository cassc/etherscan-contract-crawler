// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/utils/math/Math.sol";
import "./Interfaces/ITroveManager.sol";
import "./Interfaces/ILQTYStaking.sol";
import "./Interfaces/IPickleJar.sol";
import "./Interfaces/ICurveGaugeController.sol";
import "./Interfaces/IBondNFTArtwork.sol";
import "./Interfaces/IBondNFT.sol";

//import "forge-std/console.sol";

contract BondNFT is ERC721Enumerable, Ownable, IBondNFT {
    uint256 public constant CURVE_GAUGE_SLOPES_PRECISION = 1e9; // The minimum slope to get extra weight 1e-9

    IChickenBondManager public chickenBondManager;
    IBondNFTArtwork public artwork;
    ITroveManager immutable public troveManager;
    IERC20 immutable public lqtyToken;
    ILQTYStaking immutable public lqtyStaking;
    IPickleJar immutable public pickleLQTYJar;
    IERC20 immutable public pickleLQTYFarm;
    ICurveGaugeController immutable public curveGaugeController;
    address immutable public curveLUSD3CRVGauge;
    address immutable public curveLUSDFRAXGauge;

    uint256 immutable public transferLockoutPeriodSeconds;

    mapping (uint256 => BondExtraData) private idToBondExtraData;

    struct LiquityDataAddresses {
        address troveManagerAddress;
        address lqtyToken;
        address lqtyStaking;
        address pickleLQTYJar;
        address pickleLQTYFarm;
        address curveGaugeController;
        address curveLUSD3CRVGauge;
        address curveLUSDFRAXGauge;
    }

    constructor(
        string memory name_,
        string memory symbol_,
        address _initialArtworkAddress,
        uint256 _transferLockoutPeriodSeconds,
        LiquityDataAddresses memory _liquityDataAddresses // to avoid stack too deep issues
    )
        ERC721(name_, symbol_)
    {
        require(_liquityDataAddresses.troveManagerAddress != address(0), "BondNFT: _troveManagerAddress must be non-zero");
        require(_liquityDataAddresses.lqtyToken != address(0), "BondNFT: _lqtyToken must be non-zero");
        require(_liquityDataAddresses.lqtyStaking != address(0), "BondNFT: _lqtyStaking must be non-zero");
        require(_liquityDataAddresses.pickleLQTYJar != address(0), "BondNFT: _pickleLQTYJar must be non-zero");
        require(_liquityDataAddresses.pickleLQTYFarm != address(0), "BondNFT: _pickleLQTYFarm must be non-zero");
        require(_liquityDataAddresses.curveGaugeController != address(0), "BondNFT: _curveGaugeController must be non-zero");
        require(_liquityDataAddresses.curveLUSD3CRVGauge != address(0), "BondNFT: _curveLUSD3CRVGauge must be non-zero");
        require(_liquityDataAddresses.curveLUSDFRAXGauge != address(0), "BondNFT: _curveLUSDFRAXGauge must be non-zero");

        artwork = IBondNFTArtwork(_initialArtworkAddress);
        transferLockoutPeriodSeconds = _transferLockoutPeriodSeconds;
        troveManager = ITroveManager(_liquityDataAddresses.troveManagerAddress);
        lqtyToken = IERC20(_liquityDataAddresses.lqtyToken);
        lqtyStaking = ILQTYStaking(_liquityDataAddresses.lqtyStaking);
        pickleLQTYJar = IPickleJar(_liquityDataAddresses.pickleLQTYJar);
        pickleLQTYFarm = IERC20(_liquityDataAddresses.pickleLQTYFarm);
        curveGaugeController = ICurveGaugeController(_liquityDataAddresses.curveGaugeController);
        curveLUSD3CRVGauge = _liquityDataAddresses.curveLUSD3CRVGauge;
        curveLUSDFRAXGauge = _liquityDataAddresses.curveLUSDFRAXGauge;
    }

    function setAddresses(address _chickenBondManagerAddress) external onlyOwner {
        require(_chickenBondManagerAddress != address(0), "BondNFT: _chickenBondManagerAddress must be non-zero");
        require(address(chickenBondManager) == address(0), "BondNFT: setAddresses() can only be called once");

        chickenBondManager = IChickenBondManager(_chickenBondManagerAddress);
    }

    function setArtworkAddress(address _artworkAddress) external onlyOwner {
        // Make sure addresses have been set, as we'll be renouncing ownership
        require(address(chickenBondManager) != address(0), "BondNFT: setAddresses() must be called first");

        artwork = IBondNFTArtwork(_artworkAddress);
        renounceOwnership();
    }

    function mint(address _bonder, uint256 _permanentSeed) external returns (uint256, uint80) {
        requireCallerIsChickenBondsManager();

        // We actually increase totalSupply in `ERC721Enumerable._beforeTokenTransfer` when we `_mint`.
        uint256 tokenID = totalSupply() + 1;

        //Record first half of DNA
        BondExtraData memory bondExtraData;
        uint80 initialHalfDna = getHalfDna(tokenID, _permanentSeed);
        bondExtraData.initialHalfDna = initialHalfDna;
        idToBondExtraData[tokenID] = bondExtraData;

        _mint(_bonder, tokenID);

        return (tokenID, initialHalfDna);
    }

    function _uint256ToUint32(uint256 _inputAmount) internal pure returns (uint32) {
        return uint32(Math.min(_inputAmount / 1e18, type(uint32).max));
    }

    function setFinalExtraData(address _bonder, uint256 _tokenID, uint256 _permanentSeed) external returns (uint80) {
        requireCallerIsChickenBondsManager();

        // let’s build the struct first in memory
        BondExtraData memory tmpBondExtraData = idToBondExtraData[_tokenID];

        uint80 newDna = getHalfDna(_tokenID, _permanentSeed);
        tmpBondExtraData.finalHalfDna = newDna;

        // Liquity Data
        // Trove
        tmpBondExtraData.troveSize = _uint256ToUint32(troveManager.getTroveDebt(_bonder));
        // LQTY
        uint256 pickleLQTYAmount;
        if (pickleLQTYJar.totalSupply() > 0) {
            pickleLQTYAmount = (pickleLQTYJar.balanceOf(_bonder) + pickleLQTYFarm.balanceOf(_bonder)) * pickleLQTYJar.getRatio();
        }
        tmpBondExtraData.lqtyAmount = _uint256ToUint32(
            lqtyToken.balanceOf(_bonder) + lqtyStaking.stakes(_bonder) + pickleLQTYAmount
        );
        // Curve Gauge votes
        (uint256 curveLUSD3CRVGaugeSlope,,) = curveGaugeController.vote_user_slopes(_bonder, curveLUSD3CRVGauge);
        (uint256 curveLUSDFRAXGaugeSlope,,) = curveGaugeController.vote_user_slopes(_bonder, curveLUSDFRAXGauge);
        tmpBondExtraData.curveGaugeSlopes = _uint256ToUint32((curveLUSD3CRVGaugeSlope + curveLUSDFRAXGaugeSlope) * CURVE_GAUGE_SLOPES_PRECISION);

        // finally copy from memory to storage
        idToBondExtraData[_tokenID] = tmpBondExtraData;

        return newDna;
    }

    function getHalfDna(uint256 _tokenID, uint256 _permanentSeed) internal view returns (uint80) {
        return uint80(uint256(keccak256(abi.encode(_tokenID, block.timestamp, _permanentSeed))));
    }

    function requireCallerIsChickenBondsManager() internal view {
        require(msg.sender == address(chickenBondManager), "BondNFT: Caller must be ChickenBondManager");
    }

    function tokenURI(uint256 _tokenID) public view virtual override returns (string memory) {
        require(_exists(_tokenID), "BondNFT: URI query for nonexistent token");

        return address(artwork) != address(0) ? artwork.tokenURI(_tokenID, idToBondExtraData[_tokenID]) : "";
    }

    // Prevent transfers for a period of time after chickening in or out
    function _beforeTokenTransfer(address _from, address _to, uint256 _tokenID) internal virtual override {
        if (_from != address(0)) {
            (,,, uint256 endTime, uint8 status) = chickenBondManager.getBondData(_tokenID);

            require(
                status == uint8(IChickenBondManager.BondStatus.active) ||
                block.timestamp >= endTime + transferLockoutPeriodSeconds,
                "BondNFT: cannot transfer during lockout period"
            );
        }

        super._beforeTokenTransfer(_from, _to, _tokenID);
    }

    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount) {
        (amount,,,,) = chickenBondManager.getBondData(_tokenID);
    }

    function getBondClaimedBLUSD(uint256 _tokenID) external view returns (uint256 claimedBLUSD) {
        (,claimedBLUSD,,,) = chickenBondManager.getBondData(_tokenID);
    }

    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime) {
        (,,startTime,,) = chickenBondManager.getBondData(_tokenID);
    }

    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime) {
        (,,, endTime,) = chickenBondManager.getBondData(_tokenID);
    }

    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna) {
        return idToBondExtraData[_tokenID].initialHalfDna;
    }

    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna) {
        return uint256(idToBondExtraData[_tokenID].initialHalfDna);
    }

    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna) {
        return idToBondExtraData[_tokenID].finalHalfDna;
    }

    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna) {
        BondExtraData memory bondExtraData = idToBondExtraData[_tokenID];
        return (uint256(bondExtraData.initialHalfDna) << 128) + uint256(bondExtraData.finalHalfDna);
    }

    function getBondStatus(uint256 _tokenID) external view returns (uint8 status) {
        (,,,, status) = chickenBondManager.getBondData(_tokenID);
    }

    function getBondExtraData(uint256 _tokenID)
        external
        view
        returns (
            uint80 initialHalfDna,
            uint80 finalHalfDna,
            uint32 troveSize,
            uint32 lqtyAmount,
            uint32 curveGaugeSlopes
        )
    {
        BondExtraData memory bondExtraData = idToBondExtraData[_tokenID];
        return (
            bondExtraData.initialHalfDna,
            bondExtraData.finalHalfDna,
            bondExtraData.troveSize,
            bondExtraData.lqtyAmount,
            bondExtraData.curveGaugeSlopes
        );
    }
}