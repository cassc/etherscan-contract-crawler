// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

/**
 * @title ERC20Distribution
 * @dev A token distribution contract that sells an initial supply of tokens at a
   linearly decreasing exchange rate. After depletion of the initial supply, tokens
   can be recycled and resold at the end rate
 */
contract ERC20Distribution is Pausable, AccessControlEnumerable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;
    
    bytes32 public constant KYCMANAGER_ROLE = keccak256("KYCMANAGER_ROLE");
 
    event TokensSold(address recipient, uint256 amountToken, uint256 amountEth, uint256 actualRate);
    
    IERC20 public _trusted_token;
    address payable public _beneficiary;

    address public _kyc_approver; // address that signs the KYC approval

    uint256 private _startrate_distribution_e18; // stored internally in high res
    uint256 private _endrate_distribution_e18;   // stored internally in high res
    
    uint256 private _total_distribution_balance;  // total volume of initial distribution
    uint256 private _current_distributed_balance; // total volume sold upto now

    /**
     * @dev Creates a distribution contract that sells any ERC20 _trusted_token to the
     * beneficiary, based on a linear exchange rate
     * @param distToken address of the token contract whose tokens are distributed
     * @param distBeneficiary address of the beneficiary to whom received Ether is sent
     * @param distStartRate exchange rate at start of distribution
     * @param distEndRate exhange rate at the end of distribution
     * @param distVolumeTokens total distribution volume
    */
    constructor(
        IERC20 distToken,
        address payable distBeneficiary,
        uint256 distStartRate,
        uint256 distEndRate,
        uint256 distVolumeTokens
    ) {
        require(
            distBeneficiary != address(0),
            "TokenDistribution: distBeneficiary is the zero address"
        );
        
        require(
            distStartRate > 0 && distEndRate > 0,
            "TokenDistribution: rates should > 0"
        );

        require(
            distStartRate > distEndRate,
            "TokenDistribution: start rate should be > end rate"
        );
        
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(KYCMANAGER_ROLE, _msgSender());

        _trusted_token = distToken;
        _beneficiary = distBeneficiary;
        
        _startrate_distribution_e18  = distStartRate * (10**18);
        _endrate_distribution_e18  = distEndRate * (10**18);
        
        _total_distribution_balance = distVolumeTokens;
        _current_distributed_balance = 0;
        
        // when the contract is deployed, it starts as paused
        _pause();
    }
    
    /**
        * @dev standard getter for startrate_distribution (tokens/ETH)
        */
    function startrate_distribution() public view virtual returns (uint256) {
      return _startrate_distribution_e18 / (10**18);
    }

    /**
        * @dev standard getter for endrate_distribution (tokens/ETH)
        */
    function endrate_distribution() public view virtual returns (uint256) {
      return _endrate_distribution_e18 / (10**18);
    }

    /**
      * @dev standard getter for total_distribution_balance
      */
    function total_distribution_balance() public view virtual returns (uint256) {
      return _total_distribution_balance;
    }
    
    /**
        * @dev standard getter for current_distribution_balance (ETH)
        */
    function current_distributed_balance() public view virtual returns (uint256) {
      return _current_distributed_balance;
    }

    /**
        * @dev Function that starts distribution.
        */
    function startDistribution() whenPaused public payable {
      require(
        _trusted_token.balanceOf(address(this))==_total_distribution_balance,
        'Initial distribution balance must be correct'
        );
        
      _total_distribution_balance = _trusted_token.balanceOf(address(this));

      _unpause();
    }
    
    /**
        * @dev Getter for the distribution state.
        */
    function distributionStarted() public view virtual returns (bool) {
      return !paused();
    }
    
    /**
        * @dev KYC signature check
        */
    function purchaseAllowed(bytes calldata proof, address from, uint256 validto) public view virtual returns (bool) {
      require(_kyc_approver != address(0),
        "No KYC approver set: unable to validate buyer"
      );
      
      bytes32 expectedHash =
        hashForKYC(from, validto)
          .toEthSignedMessageHash();
          
      require(expectedHash.recover(proof) == _kyc_approver,
        "KYC: invalid token"
      );
      
      require(validto > block.number,
        "KYC: token expired"
      );
      
      return true;
    }
    
    function hashForKYC(address sender, uint256 validTo) public pure returns (bytes32) {
        return keccak256(abi.encode(sender, validTo));
    }
    
    /**
        * @dev Function that sets a new KYC Approver address
        */
    function changeKYCApprover(address newKYCApprover) public {
      require(
          hasRole(KYCMANAGER_ROLE, _msgSender()),
          "KYC: _msgSender() does not have the KYC manager role"
      );
        
      _kyc_approver = newKYCApprover;
    }
    
    // After distribution has started, the contract can no longer be paused
    // function pause() public {
    //     require(hasRole(PAUSER_ROLE, _msgSender()));
    //     _pause();
    // }

    /**
        * @dev Function that calculates the current distribution rate based
        * on the inital distribution volume and the remaining volume.
        */
    function currentRate() public view returns (uint256) {
        if(paused()) {
          // fixed rate (initial distribution slope)
          // return _startrate_distribution_e18 / (10**18);
          return 0;
        }
        
        if(_current_distributed_balance<_total_distribution_balance) {
          // Distribution active: fractional linear rate (distribution slope)
          uint256 rateDelta_e18 =
            _startrate_distribution_e18.sub(_endrate_distribution_e18);
          uint256 offset_e18 =
            _total_distribution_balance.sub(_current_distributed_balance);
          uint256 currentRate_e18 =
            _endrate_distribution_e18
            .add(rateDelta_e18.mul(offset_e18)
            .div(_total_distribution_balance));
          return currentRate_e18 / (10**18);
        } else {
          // distribution ended
          return 0;
        }
    }
    
    /**
        * @dev Function that allows the beneficiary the retrieve
              the current ether balance from the distribution contract
        */
    function claim() public {
      require(msg.sender==_beneficiary,
          "Claim: only the beneficiary can claim funds from the distribution contract"
      );
      
      _beneficiary.transfer(address(this).balance);
    }
    
    /**
        * @dev Function that is used to purchase tokens at the given rate.
          Calculates total number of tokens that can be bought for the given Ether
          value, transfers the tokens to the sender. Transfers the received
          Ether to the benificiary address
        * @param limitrate purchase tokens only at this rate or above
        * @param proof proof data for kyc validation
        * @param validTo expiry block for kyc proof
        */
        function purchaseTokens(
          uint256 limitrate,
          bytes calldata proof,
          uint256 validTo) public payable {
          
          // anyone but contract admins must pass kyc
          if(hasRole(DEFAULT_ADMIN_ROLE, _msgSender())==false) {
            require(
              purchaseAllowed(proof, msg.sender, validTo),
              "Buyer did not pass KYC procedure"
            );
          }

          uint256 actualrate = currentRate();
          require(actualrate>0,
            "unable to sell at the given rate: distribution has ended"
          );

          require(
            actualrate>=limitrate,
            "unable to sell: current rate is below requested rate"
          );
          
          uint256 tokenbalance = msg.value.mul(actualrate);
          
          uint256 pool_balance = _trusted_token.balanceOf(address(this));
          require(tokenbalance<=pool_balance,
            "insufficient tokens available in the distribution pool"
          );
          
          _current_distributed_balance = _current_distributed_balance.add(tokenbalance);

          _trusted_token.transfer(msg.sender, tokenbalance);

          emit TokensSold(msg.sender, msg.value, tokenbalance, actualrate);
        }
    }