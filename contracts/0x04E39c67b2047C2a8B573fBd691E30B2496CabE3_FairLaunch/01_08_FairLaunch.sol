// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//............................................................................................................................
//.BBBBBBBBBBBBBBBBBBBBBB...........BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPPPPPPPPPPPPPPP........
//.BBBBBBBBBBBBBBBBBBBBBBBB.........BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPPPPPPPPPPPPPPPPP......
//.BBBBBBBBBBBBBBBBBBBBBBBBB........BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPPPPPPPPPPPPPPPPPP.....
//.BBBBBBBBBBBBBBBBBBBBBBBBBB.......BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPPPPPPPPPPPPPPPPPPP....
//.BBBBBBBBBBBBBBBBBBBBBBBBBB.......BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPPPPPPPPPPPPPPPPPPPP...
//.BBBBBBBB........BBBBBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP......PPPPPPPPPPPP...
//.BBBBBBBB..........BBBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.........PPPPPPPPPP..
//.BBBBBBBB...........BBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBB...........BBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBB...........BBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBB...........BBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP...........PPPPPPPP..
//.BBBBBBBB..........BBBBBBBBB......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBB.......BBBBBBBBBBB.......BEEEEEEE.......................EEEEEEEE......................EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBBBBBBBBBBBBBBBBBBB........BEEEEEEEEEEEEEEEEEEEEEEEE......EEEEEEEEEEEEEEEEEEEEEEEE......EPPPPPPP..........PPPPPPPPP..
//.BBBBBBBBBBBBBBBBBBBBBBBB.........BEEEEEEEEEEEEEEEEEEEEEEEE......EEEEEEEEEEEEEEEEEEEEEEEE......EPPPPPPP.........PPPPPPPPP...
//.BBBBBBBBBBBBBBBBBBBBBBBB.........BEEEEEEEEEEEEEEEEEEEEEEEE......EEEEEEEEEEEEEEEEEEEEEEEE......EPPPPPPP.....PPPPPPPPPPPPP...
//.BBBBBBBBBBBBBBBBBBBBBBBBBB.......BEEEEEEEEEEEEEEEEEEEEEEEE......EEEEEEEEEEEEEEEEEEEEEEEE......EPPPPPPPPPPPPPPPPPPPPPPPPP...
//.BBBBBBBBBBBBBBBBBBBBBBBBBBB......BEEEEEEEEEEEEEEEEEEEEEEEE......EEEEEEEEEEEEEEEEEEEEEEEE......EPPPPPPPPPPPPPPPPPPPPPPPP....
//.BBBBBBBB.......BBBBBBBBBBBBB.....BEEEEEEE.......................EEEEEEEE......................EPPPPPPPPPPPPPPPPPPPPPPP.....
//.BBBBBBBB...........BBBBBBBBB.....BEEEEEEE.......................EEEEEEEE......................EPPPPPPPPPPPPPPPPPPPPPP......
//.BBBBBBBB............BBBBBBBB.....BEEEEEEE.......................EEEEEEEE......................EPPPPPPPPPPPPPPPPPPPP........
//.BBBBBBBB............BBBBBBBBB....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB............BBBBBBBBB....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB............BBBBBBBBB....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB............BBBBBBBBB....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB............BBBBBBBBB....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB...........BBBBBBBBB.....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBB........BBBBBBBBBBBB.....BEEEEEEE.......................EEEEEEEE......................EPPPPPPP.....................
//.BBBBBBBBBBBBBBBBBBBBBBBBBBBB.....BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPP.....................
//.BBBBBBBBBBBBBBBBBBBBBBBBBBB......BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPP.....................
//.BBBBBBBBBBBBBBBBBBBBBBBBBB.......BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPP.....................
//.BBBBBBBBBBBBBBBBBBBBBBBBB........BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPP.....................
//.BBBBBBBBBBBBBBBBBBBBBBB..........BEEEEEEEEEEEEEEEEEEEEEEEEE.....EEEEEEEEEEEEEEEEEEEEEEEEEE....EPPPPPPP.....................
//............................................................................................................................

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract FairLaunch is ReentrancyGuard, Ownable {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;

    /* ======== VARIABLES ======== */

    address public token;
    address public whitelistSigner;
    address payable public treasury;

    uint256 public rate;
    uint256 public ethRaised;
    uint256 public endICO;
    uint256 public minPurchase;
    uint256 public maxPurchase;
    uint256 public availableTokensICO;
    uint256 public boughtTokensICO;

    bool public buyActive = true;
    bool public withdrawActive = true;
    bool public whitelistActive = true;

    // bytes32 -> DomainSeparator
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 -> PRESALE_TYPEHASH
    bytes32 public constant PRESALE_TYPEHASH = keccak256("FairLaunch(address buyer)");

    /* ======== STRUCTS ======== */

    struct Investor {
        address wallet;
        uint256 amountToReceive;
        uint256 ethSpend;
    }

    /* ======== MAPPINGS ======== */

    mapping(address => Investor) public investor;

    /* ======== EVENTS ======== */

    event TokensPurchased(address indexed _beneficiary, address indexed _treasury, uint256 _amount);
    event SetICO(uint256 _block);
    event TokenAddress(address token);
    event WithdrawLeftovers(address _receipent, uint256 _amount);
    event WithdrawRewards(address _receipent, uint256 _amount);
    event MinPurchase(uint256 _amount);
    event MaxPurchase(uint256 _amount);
    event Rate(uint256 _amount);
    event AvailableTokensICO(uint256 _amount);
    event Sales(bool _buyActive, bool _withdrawActive);
    event WhitelistActive(bool _whitelistActive);
    event WhitelistSigner(address _whitelistSigner);
    event Treasury(address payable _amount);

    /* ======== MODIFIERS ======== */

    modifier icoActive() {
        require(endICO > 0 && block.number < endICO && availableTokensICO > 0, "ICO must be active");
        _;
    }
    
    modifier icoNotActive() {
        require(endICO < block.number, 'ICO is active');
        _;
    }

    modifier withdrawIsActive() {
        require(withdrawActive, 'Withdrawing has been paused');
        _;
    }

    modifier buyIsActive() {
        require(buyActive, 'Purchasing has been paused');
        _;
    }

    /* ======== INITIALIZATION ======== */

    constructor (
        address payable _treasury,
        uint256 _rate, 
        uint256 _availableTokensICO,
        uint256 _endICO, 
        uint256 _minPurchase, 
        uint256 _maxPurchase
    ) public {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("FairLaunch")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );

        setRate(_rate);
        setICO(_endICO);
        setMaxPurchase(_maxPurchase);
        setMinPurchase(_minPurchase);
        setAvailableTokensICO(_availableTokensICO);
        setWhitelistSigner(_msgSender());
        setTreasury(_treasury);
    }
    
    /* ======== SETTERS ======== */

    /**
    * @notice Set the new end ICO, when setting this to 0 the ico will be done
    * @param _whitelistActive Sets the whitelist active or not
    */
    function setWhitelistActive(bool _whitelistActive) public onlyOwner {
        whitelistActive = _whitelistActive;

        emit WhitelistActive(_whitelistActive);
    }

    /**
    * @notice Set the new signer of the whitelisters
    * @param _whitelistSigner The new whitelist signer
    */
    function setWhitelistSigner(address _whitelistSigner) public onlyOwner {
        whitelistSigner = _whitelistSigner;

        emit WhitelistSigner(_whitelistSigner);
    }

    /**
    * @notice Set the new end ICO, when setting this to 0 the ico will be done
    * @param _ICO The end ico block
    */
    function setICO(uint256 _ICO) public onlyOwner {
        endICO = _ICO;

        emit SetICO(_ICO);
    }

    /**
    * @notice Set Token Address
    * @param _token The token address the presale is about
    */
    function setToken(address _token) public onlyOwner {
        require(_token != address(0x0), "FairLaunch: Token is the zero address");
        token = _token;

        emit TokenAddress(_token);
    }

    /**
    * @notice Sets the new rate
    * @param _rate The rate in (Gwei)
    */
    function setRate(uint256 _rate) public onlyOwner {
        require(_rate > 0, "FairLaunch: Cannot be 0");
        rate = _rate;

        emit Rate(rate);
    }
    
    /**
    * @notice Sets the available tokens
    * @param _availableTokensICO the available tokens in gwei
    */
    function setAvailableTokensICO(uint256 _availableTokensICO) public onlyOwner {
        availableTokensICO = _availableTokensICO;

        emit AvailableTokensICO(_availableTokensICO);
    }
    
    /**
    * @notice Sets the new receiver of the funds
    * @param _treasury The address that will receive the presale funds
    */
    function setTreasury(address payable _treasury) public onlyOwner {
        require(_treasury != address(0), "FairLaunch: Invalid address");
        treasury = _treasury;
        
        emit Treasury(treasury);
    }
    
    /**
    * @notice Sets the new min purchase 
    * @param _minPurchase The new min purchase in (Gwei)
    */
    function setMinPurchase(uint256 _minPurchase) public onlyOwner {
        minPurchase = _minPurchase;

        emit MinPurchase(_minPurchase);
    }

    /**
    * @notice Sets the new max purchase 
    * @param _maxPurchase The new max purchase in (Gwei)
    */
    function setMaxPurchase(uint256 _maxPurchase) public onlyOwner {
        maxPurchase = _maxPurchase;

        emit MaxPurchase(_maxPurchase);
    }

    /**
    * @notice Sets the activity of buy / withdraw 
    * @param _buyActive Enable or disable the buy activity
    * @param _withdrawActive Enable or disable the withdraw activty
    */
    function setSales(bool _buyActive, bool _withdrawActive) public onlyOwner {
        buyActive = _buyActive;
        withdrawActive = _withdrawActive;

        emit Sales(_buyActive, _withdrawActive);
    }

    /* ======== GETTERS ======== */

    /**
    * @notice Returns the token amount based on the rewardTokenCount and the rate
    * @param _weiAmount The amount of tokens in wei
    */
    function getTokenAmount(uint256 _weiAmount) public view returns (uint256) {
        return (_weiAmount * rate) / 1E18;
    }

    /**
    * @notice Returns the amount of tokens in the contract
    */
    function getTokensInContract() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }

    /**
    * @notice Returns the amount the user can withdraw after the ICO has ended
    * @param _beneficiary The wallet address for distributed amount
    */
    function withdrawalAmount(address _beneficiary) public view returns (uint256 amount) {
        return investor[_beneficiary].amountToReceive;
    }

    /* ======== CALLABLE FUNCTIONS ======== */

    /**
    * @notice deposit the tokens which will be claimed
    */
    function depositTokens(uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(_msgSender(), address(this), amount);
    }

    /**
    * @notice If the ICO is not active anymore, the owner can withdraw the leftovers
    */
    function withdrawLeftoversToken() external icoNotActive onlyOwner {
        require(IERC20(token).balanceOf(address(this)) > 0, 'FairLaunch: There are no tokens to withdraw');
        IERC20(token).safeTransfer(_msgSender(), IERC20(token).balanceOf(address(this)));

        emit WithdrawLeftovers(_msgSender(), IERC20(token).balanceOf(address(this)));
    }

    /**
    * @notice Users can withdraw only when the ICO is ended and the amount is not equal to 0
    */
    function withdrawTokens() external nonReentrant icoNotActive withdrawIsActive {
        require(token != address(0), "FairLaunch: Token is the zero address");
        require(withdrawalAmount(_msgSender()) != 0, "FairLaunch: Haven't bought any tokens");
        require(withdrawalAmount(_msgSender()) <= getTokensInContract(), "FairLaunch: Not enough tokens in contract to withdraw from");

        uint256 amountToWithdraw = withdrawalAmount(_msgSender());
        investor[_msgSender()].amountToReceive = 0;

        IERC20(token).safeTransfer(_msgSender(), amountToWithdraw);

        emit WithdrawRewards(_msgSender(), amountToWithdraw);
    }

    /**
    * @notice Buy tokens
    */
    function buyTokens(bytes memory _signature) external nonReentrant icoActive buyIsActive payable {
        require(availableTokensICO != 0, "FairLaunch: No available tokens left");
        if(whitelistActive) {
            bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, keccak256(abi.encode(PRESALE_TYPEHASH, _msgSender()))));
            address recoveredAddress = digest.recover(_signature);
            require(recoveredAddress != address(0) && recoveredAddress == address(whitelistSigner), "Invalid signature");
        }

        uint256 ethPurchaseInWei = msg.value;
        uint256 tokensPurchase = getTokenAmount(ethPurchaseInWei);
        require(ethPurchaseInWei >= minPurchase, 'FairLaunch: Have to send at least minPurchase');
        require(tokensPurchase != 0, "FairLaunch: Value is 0");
        require(tokensPurchase <= availableTokensICO, "FairLaunch: No tokens left for purchase");
        require((investor[_msgSender()].ethSpend + ethPurchaseInWei) <= maxPurchase, 'FairLaunch: Max purchase has been reached');

        // Amount of ETH that has been raised
        ethRaised += ethPurchaseInWei;

        // Add person to distributed map and tokens bought
        investor[_msgSender()].wallet = _msgSender();
        investor[_msgSender()].amountToReceive += tokensPurchase;
        investor[_msgSender()].ethSpend += ethPurchaseInWei;
    
        availableTokensICO = availableTokensICO - tokensPurchase;
        boughtTokensICO += tokensPurchase;

        treasury.transfer(ethPurchaseInWei);

        emit TokensPurchased(_msgSender(), treasury, tokensPurchase);
    }
}