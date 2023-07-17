// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import { IFujiERC1155 } from "./IFujiERC1155.sol";
import { FujiBaseERC1155 } from "./FujiBaseERC1155.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { WadRayMath } from "../Libraries/WadRayMath.sol";
import { MathUtils } from "../Libraries/MathUtils.sol";
import { Errors } from "../Libraries/Errors.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

contract F1155Manager is Ownable {
  using Address for address;

  // Controls for Mint-Burn Operations
  mapping(address => bool) public addrPermit;

  modifier onlyPermit() {
    require(addrPermit[_msgSender()] || msg.sender == owner(), Errors.VL_NOT_AUTHORIZED);
    _;
  }

  function setPermit(address _address, bool _permit) public onlyOwner {
    require((_address).isContract(), Errors.VL_NOT_A_CONTRACT);
    addrPermit[_address] = _permit;
  }
}

contract FujiERC1155 is IFujiERC1155, FujiBaseERC1155, F1155Manager {
  using WadRayMath for uint256;

  //FujiERC1155 Asset ID Mapping

  //AssetType => asset reference address => ERC1155 Asset ID
  mapping(AssetType => mapping(address => uint256)) public assetIDs;

  //Control mapping that returns the AssetType of an AssetID
  mapping(uint256 => AssetType) public assetIDtype;

  uint64 public override qtyOfManagedAssets;

  //Asset ID  Liquidity Index mapping
  //AssetId => Liquidity index for asset ID
  mapping(uint256 => uint256) public indexes;

  // Optimizer Fee expressed in Ray, where 1 ray = 100% APR
  //uint256 public optimizerFee;
  //uint256 public lastUpdateTimestamp;
  //uint256 public fujiIndex;

  /// @dev Ignoring leap years
  //uint256 internal constant SECONDS_PER_YEAR = 365 days;

  constructor() public {
    //fujiIndex = WadRayMath.ray();
    //optimizerFee = 1e24;
  }

  /**
   * @dev Updates Index of AssetID
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   * @param newBalance: Amount
   **/
  function updateState(uint256 _assetID, uint256 newBalance) external override onlyPermit {
    uint256 total = totalSupply(_assetID);

    if (newBalance > 0 && total > 0 && newBalance > total) {
      uint256 diff = newBalance.sub(total);

      uint256 amountToIndexRatio = (diff.wadToRay()).rayDiv(total.wadToRay());

      uint256 result = amountToIndexRatio.add(WadRayMath.ray());

      result = result.rayMul(indexes[_assetID]);
      require(result <= type(uint128).max, Errors.VL_INDEX_OVERFLOW);

      indexes[_assetID] = uint128(result);

      // TODO: calculate interest rate for a fujiOptimizer Fee.
      /*
      if(lastUpdateTimestamp==0){
        lastUpdateTimestamp = block.timestamp;
      }

      uint256 accrued = _calculateCompoundedInterest(
        optimizerFee,
        lastUpdateTimestamp,
        block.timestamp
      ).rayMul(fujiIndex);

      fujiIndex = accrued;
      lastUpdateTimestamp = block.timestamp;
      */
    }
  }

  /**
   * @dev Returns the total supply of Asset_ID with accrued interest.
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function totalSupply(uint256 _assetID) public view virtual override returns (uint256) {
    // TODO: include interest accrued by Fuji OptimizerFee

    return super.totalSupply(_assetID).rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns the scaled total supply of the token ID. Represents sum(token ID Principal /index)
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledTotalSupply(uint256 _assetID) public view virtual returns (uint256) {
    return super.totalSupply(_assetID);
  }

  /**
   * @dev Returns the principal + accrued interest balance of the user
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function balanceOf(address _account, uint256 _assetID)
    public
    view
    override(FujiBaseERC1155, IFujiERC1155)
    returns (uint256)
  {
    uint256 scaledBalance = super.balanceOf(_account, _assetID);

    if (scaledBalance == 0) {
      return 0;
    }

    // TODO: include interest accrued by Fuji OptimizerFee
    return scaledBalance.rayMul(indexes[_assetID]);
  }

  /**
   * @dev Returns the balance of User, split into owed amounts to BaseProtocol and FujiProtocol
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  /*
  function splitBalanceOf(
    address _account,
    uint256 _assetID
  ) public view override returns (uint256,uint256) {
    uint256 scaledBalance = super.balanceOf(_account, _assetID);
    if (scaledBalance == 0) {
      return (0,0);
    } else {
    TO DO COMPUTATION
      return (baseprotocol, fuji);
    }
  }
  */

  /**
   * @dev Returns Scaled Balance of the user (e.g. balance/index)
   * @param _account: address of the User
   * @param _assetID: ERC1155 ID of the asset which state will be updated.
   **/
  function scaledBalanceOf(address _account, uint256 _assetID)
    public
    view
    virtual
    returns (uint256)
  {
    return super.balanceOf(_account, _assetID);
  }

  /**
   * @dev Returns the sum of balance of the user for an AssetType.
   * This function is used for when AssetType have units of account of the same value (e.g stablecoins)
   * @param _account: address of the User
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   **/
  /*
  function balanceOfBatchType(address _account, AssetType _type) external view override returns (uint256 total) {

    uint256[] memory IDs = engagedIDsOf(_account, _type);

    for(uint i; i < IDs.length; i++ ){
      total = total.add(balanceOf(_account, IDs[i]));
    }
  }
  */

  /**
   * @dev Mints tokens for Collateral and Debt receipts for the Fuji Protocol
   * Emits a {TransferSingle} event.
   * Requirements:
   * - `_account` cannot be the zero address.
   * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
   * acceptance magic value.
   * - `_amount` should be in WAD
   */
  function mint(
    address _account,
    uint256 _id,
    uint256 _amount,
    bytes memory _data
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];
    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

    _balances[_id][_account] = accountBalance.add(amountScaled);
    _totalSupply[_id] = assetTotalBalance.add(amountScaled);

    emit TransferSingle(operator, address(0), _account, _id, _amount);

    _doSafeTransferAcceptanceCheck(operator, address(0), _account, _id, _amount, _data);
  }

  /**
   * @dev [Batched] version of {mint}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   * - If `_to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
   * acceptance magic value.
   */
  function mintBatch(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _amounts,
    bytes memory _data
  ) external onlyPermit {
    require(_to != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      accountBalance = _balances[_ids[i]][_to];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0, Errors.VL_INVALID_MINT_AMOUNT);

      _balances[_ids[i]][_to] = accountBalance.add(amountScaled);
      _totalSupply[_ids[i]] = assetTotalBalance.add(amountScaled);
    }

    emit TransferBatch(operator, address(0), _to, _ids, _amounts);

    _doSafeBatchTransferAcceptanceCheck(operator, address(0), _to, _ids, _amounts, _data);
  }

  /**
   * @dev Destroys `_amount` receipt tokens of token type `_id` from `account` for the Fuji Protocol
   * Requirements:
   * - `account` cannot be the zero address.
   * - `account` must have at least `_amount` tokens of token type `_id`.
   * - `_amount` should be in WAD
   */
  function burn(
    address _account,
    uint256 _id,
    uint256 _amount
  ) external override onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);

    address operator = _msgSender();

    uint256 accountBalance = _balances[_id][_account];
    uint256 assetTotalBalance = _totalSupply[_id];

    uint256 amountScaled = _amount.rayDiv(indexes[_id]);

    require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

    _balances[_id][_account] = accountBalance.sub(amountScaled);
    _totalSupply[_id] = assetTotalBalance.sub(amountScaled);

    emit TransferSingle(operator, _account, address(0), _id, _amount);
  }

  /**
   * @dev [Batched] version of {burn}.
   * Requirements:
   * - `_ids` and `_amounts` must have the same length.
   */
  function burnBatch(
    address _account,
    uint256[] memory _ids,
    uint256[] memory _amounts
  ) external onlyPermit {
    require(_account != address(0), Errors.VL_ZERO_ADDR_1155);
    require(_ids.length == _amounts.length, Errors.VL_INPUT_ERROR);

    address operator = _msgSender();

    uint256 accountBalance;
    uint256 assetTotalBalance;
    uint256 amountScaled;

    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 amount = _amounts[i];

      accountBalance = _balances[_ids[i]][_account];
      assetTotalBalance = _totalSupply[_ids[i]];

      amountScaled = _amounts[i].rayDiv(indexes[_ids[i]]);

      require(amountScaled != 0 && accountBalance >= amountScaled, Errors.VL_INVALID_BURN_AMOUNT);

      _balances[_ids[i]][_account] = accountBalance.sub(amount);
      _totalSupply[_ids[i]] = assetTotalBalance.sub(amount);
    }

    emit TransferBatch(operator, _account, address(0), _ids, _amounts);
  }

  //Getter Functions

  /**
   * @dev Getter Function for the Asset ID locally managed
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function getAssetID(AssetType _type, address _addr) external view override returns (uint256 id) {
    id = assetIDs[_type][_addr];
    require(id <= qtyOfManagedAssets, Errors.VL_INVALID_ASSETID_1155);
  }

  //Setter Functions

  /**
   * @dev Sets the FujiProtocol Fee to be charged
   * @param _fee; Fee in Ray(1e27) to charge users for optimizerFee (1 ray = 100% APR)
   */
  /*
  function setoptimizerFee(uint256 _fee) public onlyOwner {
    require(_fee >= WadRayMath.ray(), Errors.VL_OPTIMIZER_FEE_SMALL);
    optimizerFee = _fee;
  }
  */

  /**
   * @dev Sets a new URI for all token types, by relying on the token type ID
   */
  function setURI(string memory _newUri) public onlyOwner {
    _uri = _newUri;
  }

  /**
   * @dev Adds and initializes liquidity index of a new asset in FujiERC1155
   * @param _type: enum AssetType, 0 = Collateral asset, 1 = debt asset
   * @param _addr: Reference Address of the Asset
   */
  function addInitializeAsset(AssetType _type, address _addr)
    external
    override
    onlyPermit
    returns (uint64)
  {
    require(assetIDs[_type][_addr] == 0, Errors.VL_ASSET_EXISTS);

    assetIDs[_type][_addr] = qtyOfManagedAssets;
    assetIDtype[qtyOfManagedAssets] = _type;

    //Initialize the liquidity Index
    indexes[qtyOfManagedAssets] = WadRayMath.ray();
    qtyOfManagedAssets++;

    return qtyOfManagedAssets - 1;
  }
  /**
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param _rate The interest rate, in ray
   * @param _lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  /*
  function _calculateCompoundedInterest(
    uint256 _rate,
    uint256 _lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp.sub(uint256(_lastUpdateTimestamp));

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = _rate / SECONDS_PER_YEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = exp.mul(expMinusOne).mul(basePowerTwo) / 2;
    uint256 thirdTerm = exp.mul(expMinusOne).mul(expMinusTwo).mul(basePowerThree) / 6;

    return WadRayMath.ray().add(ratePerSecond.mul(exp)).add(secondTerm).add(thirdTerm);
  }
  */
}