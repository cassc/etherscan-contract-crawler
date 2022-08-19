// SPDX-License-Identifier: MIT

pragma solidity >=0.8.1;

// Interfaces
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Gemini Shield Implementation
import "./Shield.sol";

// Enums
import "./ROCK2ENUM.sol";

// Data
import "./TokenSwapSimpleDATA.sol";
import "./AddressTree2DATA.sol";
import "./ROCK2DATA.sol";

// Interfaces
import "./TokenSwap.sol";
import "./ROCK2INTERFACE.sol";
import "./MiniERC20.sol";


contract ROCKSHIELD is ROCK2DATA,                 AddressTree2DATA, Shield,                                                           TokenSwapSimpleDATA,           ROCK2INTERFACE {


    constructor(string memory name_, string memory symbol_) Shield() ROCK2DATA(name_, symbol_) AddressTree2DATA() {  }


    uint8 lastBT = uint8(Balance.blocked)+6;


    /* Basic ERC 20 Meta Functionality */


    function name() public view override returns (string memory) {
      return _name;
    }
    function symbol() public view override returns (string memory) {
      return _symbol;
    }

    function decimals() public view override returns (uint8) {
      return _decimals;
    }


    function totalSupply() public view override returns (uint256) {
      return _totalSupplyERC20 + _totalSupplyBlocked;
    }


    function balanceOf(address account) public override view returns (uint256) {
    if (r[account].b[uint8(Balance.isNoticed)] > 0) {
      return r[account].b[uint8(Balance.erc20)];
    }
    return 0;
    }






    ////////// Gemini's Real Time Provisioning Implementation  - helpers ///////////////////////////


    function hasDig(address sender) public view override returns (bool) {
     return r[sender].dCount>0;
    }

    function getPrice() public override view returns ( uint256 price, address currency, uint8 decimal, uint256 forSale) {
     return (
       _digPrice,
       _digCurrency,
       _digDecimals,
       _digForSale
     );
    }



    ////////// Gemini's SelfStaking / Rocking Implementation  - helpers ///////////////////////////


    function getAPY() public override view returns (uint256) {
       return _apy;
    }

    function getAPY( uint256 now_ ) public override  view returns (uint256 rate, uint256 from, uint256 till, bool valid ) {
      uint256 _apyTillDate = _apySetDate + _apyValid;
      return (
        _apy,
        _apySetDate,
        _apyTillDate,
        now_ >= _apyTillDate
      );
    }






    ////////// ISD's  ROCK Implementation - specific helpers ///////////////////////////


    function deployedBy() public pure returns (string memory) {
        return "Interactive Software Development LLC";
    }


    function getTimeStamp() public view override returns (uint256) {
        return block.timestamp;
    }


    function totalFlow(address currency) public view override returns (uint) {
        return _totalFlow[currency];
    }
    function totalBalance() public view override returns (uint256) {
        return (payable(address(this))).balance;
    }


    function isProtected(address account) public view override returns (bool) {
      if (r[account].b[uint8(Balance.isNoticed)] > 0) {
        return r[account].b[uint8(Balance.protected)] != 0;
      }
      return false;
    }


      function totals() public view  override returns (uint256 [5] memory) {
          return [
          _totalSupplyERC20,
          _totalSupplyBlocked,
          _totalSummarized,
          _totalSummarizedAPY,
          _totalDigged
        ];
      }

      function notice(address account, bool f) internal {
        RockEntry storage rm = r[ account ];
        if (rm.b[uint8(Balance.isNoticed)] == 0) {
          rm.b[uint8(Balance.isNoticed)] = block.timestamp;
          if (f == true) {
            balancedAddress.push(account);
          }
        }
      }

      function balancesOf( address account) public view override returns (uint256 [16] memory b) {

        for (uint8 i =0; i< 16; i++) {

          // member or naked => if protected, we do not show these values
          if (r[account].b[uint8(Balance.protected)]>0 && msg.sender != account) {
            if (  i >= uint8(Balance.blocked) && i <= lastBT ) {
                // keep balance zero
                continue;
            }
          }

          // regged member
          if (mExists[account] == true){
            b[i] = r[account].b[i];
            continue;
          }

          // naked
          if ( i == uint8(Balance.erc20)
            || i == uint8(Balance.blocked) ) {
              b[i] = r[account].b[i];
              continue;
            }
        }

        return b;
      }


     function getFee() public override view returns (uint256 fee, uint96 unit){
       return ( _rockFee, _rockFeeUnit); // ETHEREUM
     }

     function lastBlockingOf(address account) public override view returns (uint256) {
       if (r[account].b[uint8(Balance.isNoticed)] > 0) {
         if (r[account].b[uint8(Balance.protected)]==0 || msg.sender == account) {
           uint256 r = r[account].b[lastBT];
           return r;
         }
       }
       return block.timestamp;
     }




    ////////// OpenZeppelin's ERC20 Implementation ///////////////////////////


    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        if (block.timestamp - r[owner].allowancesTime[spender] > _maxAllowanceTime) {
          return 0;
        }
        return r[owner].allowances[spender];
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }



    function transferFrom(        address sender,        address recipient,        uint256 amount    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        require(block.timestamp - r[sender].allowancesTime[_msgSender()] <= _maxAllowanceTime, "ERC20: transfer amount exceeds allowance time");

        uint256 currentAllowance = r[sender].allowances[_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual override returns (bool) {
        _approve(_msgSender(), spender, r[_msgSender()].allowances[spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual override returns (bool) {
        uint256 currentAllowance = r[_msgSender()].allowances[spender];
        require(currentAllowance >= subtractedValue, "XRC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }



    function _transfer(        address sender,        address recipient,        uint256 amount    ) internal virtual {
        require(sender != address(0), "IERC20: transfer from the zero address");
        require(recipient != address(0), "IERC20: transfer to the zero address");

        //      _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = r[sender].b[uint8(Balance.erc20)];
        require(senderBalance >= amount, "IERC20: transfer amount exceeds balance");
        unchecked {
            r[sender].b[uint8(Balance.erc20)] = senderBalance - amount;
        }


        /* WARNING: notice() registers balance for new unseen addresses */
        notice(recipient, true); // rescue relevant

        r[recipient].b[uint8(Balance.erc20)] += amount;

        emit Transfer(sender, recipient, amount);

       //      _afterTokenTransfer(sender, recipient, amount);
    }



    function _approve(        address owner,        address spender,        uint256 amount    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        r[owner].allowancesTime[spender] = block.timestamp;
        r[owner].allowances[spender] = amount;
        emit Approval(owner, spender, amount);
    }





  }