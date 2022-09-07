// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./PausableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";
import "./IERC20Upgradeable.sol";
import "./SafeERC20Upgradeable.sol";
import "./ECDSAUpgradeable.sol";
import "./Initializable.sol";

contract RobocockCrystalExchange is Initializable, PausableUpgradeable, OwnableUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // @custom:oz-upgrades-unsafe-allow constructor
    // constructor() initializer {}    

    address private _tokenAddress;

    uint256 private _exchangePrice; //  1 GKEN = 1 crystal, value should be in 1 crystal

    // mapping if an address is allowed to exchange
    mapping (address => bool) public whitelistedExchanger;

    uint256 public totalTokenReleased;
    uint256 public totalCrsytalExchanged;

    uint256 private _exchangeFee;

    mapping(uint256 => bool) usedNonces;

    event ExchangeToken(
        uint256 nativeAmount,
        uint256 tokenAmount,
        address userAddress,
        uint256 nativeAmountExchangePrice,
        uint256 fee,
        bytes sig,
        uint256 nonce
    );

    function initialize() public initializer {
        __Pausable_init();
        __Ownable_init();
       

        _exchangeFee = 3;   // exchange fee is 3%

        _exchangePrice = 1; // exchange price

        _tokenAddress = 0x0B5a6E082C8243AD568a35230B327F2c043D3d1f;
    }

    function setExchangeFee(uint256 exchangeFee) public onlyOwner {
        require(exchangeFee > 0,"Exchange Price should be greater than zero");
        _exchangeFee = exchangeFee;
    }

    function getExchangeFee() external view returns (uint256) {
        return _exchangeFee;
    }

    // token address
    function tokenAddress() external view returns (address) {
        return _tokenAddress;
    }

    function setTokenAddress(address _token) external onlyOwner {
        _tokenAddress = _token;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setExchangePrice(uint256 _newExchangePrice) external onlyOwner {
        require(_newExchangePrice > 0,"Exchange Price should be greater than zero");
        _exchangePrice = _newExchangePrice;
    }

    function getExchangePrice() external view returns (uint256) {
        return _exchangePrice;
    }

    
    modifier onlyExchanger() {
        require(whitelistedExchanger[_msgSender()],"Not whitelisted as exchanger");
        _;
    }

    function setExchanger(address _exchanger, bool _whitelisted) external onlyOwner {
        require(whitelistedExchanger[_exchanger] != _whitelisted,"Invalid value for _exchanger");
        whitelistedExchanger[_exchanger] = _whitelisted;
    }

    function isExchanger(address _exchanger) external view returns (bool) {
        return whitelistedExchanger[_exchanger];
    }
    
 
    function exchangeToken(uint256 _crystalAmount,bool _hasFee, uint256 nonce, bytes memory sig) external whenNotPaused {

        require(!usedNonces[nonce],"Used nonce");
        usedNonces[nonce] = true;

        validateData(_crystalAmount, _hasFee, nonce, sig );

        uint256 crystalAmount = _crystalAmount;
        require(crystalAmount > 0, "Amount should be greater than zero");
        require(_exchangePrice > 0,"Exchange price should be greater than zero");
        //require(_exchangeFee > 0,"Exchange Fee should be greater than zero");

        uint256 tokenAmount = crystalAmount.div(_exchangePrice);

        uint256 fee = 0;
        if(_hasFee && _exchangeFee>0){
            fee = tokenAmount.mul(_exchangeFee).div(100);
            tokenAmount = tokenAmount.sub(fee);
        }
        require(IERC20Upgradeable(_tokenAddress).balanceOf(address(this)) >= tokenAmount, "Reward pool does not have enough token balance");

        address userAddress = _msgSender();
        
        IERC20Upgradeable(_tokenAddress).safeTransfer(userAddress, tokenAmount);

        totalTokenReleased = totalTokenReleased.add(tokenAmount);

        totalCrsytalExchanged = totalCrsytalExchanged.add(crystalAmount);

        emit ExchangeToken(crystalAmount, tokenAmount, userAddress, _exchangePrice, fee, sig,nonce );
    }

    function validateData(uint256 _gAmount, bool _hasFee, uint256 _nonce, bytes memory sig ) private view {
        address _walletAddress = _msgSender();
        bytes32 signedMessage = keccak256(abi.encodePacked(_gAmount, _walletAddress, _hasFee, _nonce));
        address signer = ECDSAUpgradeable.recover(signedMessage, sig);
        require(whitelistedExchanger[signer]==true, "Not signed by the authority");
    }
}