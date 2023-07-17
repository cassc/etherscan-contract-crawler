// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

// https://defigarage.dev/
/*                                                                    
              :^^^^^^^^^^^.                                                     
              Y#J????????YGY:                                                   
              Y#.         ~#J                     ........                      
              Y#:         :#J                  ^B5JJJJJJJJ.  !G~                
              Y#:         :#J     :~~~~~~^     [email protected]           .:.                
              Y#:         :#J    5B!!!!!!PG.   [email protected]           ~B:                
              75.         :#J   .&5      [email protected]:   [email protected]    [email protected]^                
                          :#J   .#P:^^^^:[email protected]:   [email protected]???????:   [email protected]^                
                          :#J   .#G!7777777.   [email protected]           [email protected]^                
                          :#J   .&5            [email protected]           [email protected]^                
   ..................:::::Y#!    #G:......     [email protected]           [email protected]^                
:J5YJJJJJJJJJJJJJJJJJJJJJJ?^     ^JJ??????:    :5!           ^5:                
PG:                                                                             
B5                                                                              
G5                .:::::::     . .::::.  .::::::.      .::::::.     .::::::     
G5          ..    ^7777!7YG^  .BGJ7!77~  ~7777!7P5.  ^P5?7??7?&7   JP?7777?G?   
G5          !B~           &J  .&Y               [email protected]:  [email protected]     [email protected]?  :@?      Y&   
G5          !B~    ::::::^&J  .&J        .::::::[email protected]:  J&.     [email protected]?  :@? .... 5&   
G5          !B~  ^BJ!!!!!7&J  .&J       [email protected]:  J&.     [email protected]?  :&P??????YJ   
G5          !B~  [email protected]      &J  .&J       BP      [email protected]:  J&.     .&?  :@7           
5G~.        7B~  [email protected]:     ^@J  .&J       BP      [email protected]:  [email protected]~....:[email protected]?  [email protected]           
.7YJJJJJJJJJY5^  :5Y?????JG7  .P7       !5J?????YG:   [email protected]?   75J??????.   
                                                       ......!&!                
                                                      .7777777^                
*/

import {ERC20} from "./ERC20.sol";
import {SafeTransferLib} from "./SafeTransferLib.sol";
import {FixedPointMathLib} from "./FixedPointMathLib.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
contract perpetualTokenOffering is ERC20,AccessControl {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;
    ERC20 public immutable lst;
    address public ciab;
    address public team;
    uint256 public lastTotalAssets;
    uint256 public ltvOnDeposits;
    uint256 public helper;
    uint256 public threshold;
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    
    constructor(
        ERC20 _asset,
        ERC20 _lst,
        address _ciab,
        string memory _name,
        string memory _symbol

    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
        lst = _lst;
        ciab = _ciab;
        ltvOnDeposits = 80;
        team = address(0xb52f8b5E8684dbD2B2A4956305F3aBd936c51621);
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        threshold = 2000 ether;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public onlyRole(ADMIN_ROLE) returns (uint256 shares) {
        before();
        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);
        
        shares = convertToShares(assets)/10;
        
        _mint(receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        afterDeposit(assets, shares);
        afterMath();
    }

    function depositCheapeth( address receiver) public payable returns (uint256 shares) {
        require(msg.value >= 100000000000000000, "under minimum");
        uint256 _value = msg.value*9/10;
        helper = msg.value;
        before();
        shares = convertToShares(_value);
        if(totalAssets() > threshold){
            shares = shares*995/1000;
        }
        _mint(receiver, shares);
        helper  = 0;
        
        emit Deposit(msg.sender, receiver, _value, shares);
        afterDeposit(_value, shares);
        afterMath();
    }

    function convert(uint256 amount) public {
        before();
        // send in steth
        lst.safeTransferFrom(msg.sender,address(this),amount);
        // approve steth
        uint256 _size = lst.balanceOf(address(this));
        lst.approve(ciab,_size);
        // deposit into CIAB
        Iciab(ciab).deposit(_size);
        // calculate mint amount
        uint256 _toMint = _size*ltvOnDeposits/100;
        // mint synth
        Iciab(ciab).mint(_toMint);
        asset.transfer(team,_size/10);
        // get eth
        payable(msg.sender).transfer(amount);
        afterMath();
     }

    function withdraw(uint256 assets, address receiver, address owner) public   returns (uint256 shares) {
        before();
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }
        beforeWithdraw(assets, shares);
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        if(asset.balanceOf(address(this)) < assets){
            uint256 _needed = assets - asset.balanceOf(address(this));
            Iciab(ciab).mint(_needed);
        }
        asset.safeTransfer(receiver, assets);
        afterMath();
    }

    function redeem(uint256 shares, address receiver, address owner) public  returns (uint256 assets) {
        before();
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.
            if (allowed != type(uint256).max) {
                allowance[owner][msg.sender] = allowed - shares;
            }
        }
        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");
        beforeWithdraw(assets, shares);
        _burn(owner, shares);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        asset.safeTransfer(receiver, assets);
        afterMath();
    }

    function changeLTV(uint256 ratio) public {
        before();
        // require sender  = team
        require(msg.sender == team,"not team");
        ltvOnDeposits = ratio;
        // get CIAB info
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));
        uint256 _desiredDebt = (_deposit + _outstanding)*ratio/100;
        uint256 _delta;
        if(_desiredDebt < _debt){
            // repay some debt
            _delta = _debt - _desiredDebt;
            asset.approve(ciab, _delta);
            Iciab(ciab).repay(_delta);
        }
        if(_desiredDebt > _debt){
            // take some debt
            _delta = _desiredDebt - _debt;
            Iciab(ciab).mint(_delta);
        }
        afterMath();
    }

    function setTeam(address _team) public {
        require(msg.sender == team,"Y U NO TEAM");
        team = _team;
    }       

    function setThreshold(uint256 _threshold) public {
        require(msg.sender == team,"Y U NO TEAM");
        threshold = _threshold;
    }    

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view returns (uint256){
        // get CIAB info
        uint256 _deposit = Iciab(ciab).deposited(address(this));
        uint256 _debt = Iciab(ciab).debt(address(this));
        uint256 _outstanding = Iciab(ciab).Owing(address(this));
        uint256 _net = (address(this).balance - helper)*9/10 +asset.balanceOf(address(this)) + _deposit + _outstanding - _debt;
        return _net;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets*1000 : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares*1000 : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? shares*1000 : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.
        return supply == 0 ? assets*1000 : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal {}

    function afterDeposit(uint256 assets, uint256 shares) internal {}

    function before() internal {
        if(lastTotalAssets < totalAssets()){
            uint256 _delta = totalAssets() - lastTotalAssets;
            Iciab(ciab).mint(_delta);
            asset.transfer(team,_delta);
        }
    }

    function afterMath() internal {
        lastTotalAssets = totalAssets();
    }
}
interface Iciab {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function mint(uint256 amount) external;
    function repay(uint256 amount) external;
    function Owing(address _depositor) external view returns(uint256 _allocation);
    function deposited(address _depositor) external pure returns(uint256 _deposit);
    function debt(address _depositor) external pure returns(uint256 _debt);
}