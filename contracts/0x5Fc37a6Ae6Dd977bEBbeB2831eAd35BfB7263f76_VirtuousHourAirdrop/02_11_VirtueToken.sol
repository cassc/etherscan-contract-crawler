// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @author 0xNeptune
/**
  @notice VirtueToken initializes both the VIRTUE token and the VIRTUE token's associated bonding curve.
    The bonding curve is a linear interpolation of an expontential curve.
    The 'start_x' of the first bondSlice within bondCurve will be set to the
    amount of Steth within the treasury post mint but prior to the deployment
    of this contract.
*/
contract VirtueToken is ERC20Burnable {
  uint public bondedSteth;
  address public immutable idolMainAddress;
  address public immutable idolMarketAddress;

  struct bondSlice{
    uint start_x;
    int slope;
    int intercept;
  }

  bondSlice[19] internal bondCurve;

  // Curve below is for illustrative purposes, final curve will not be decided until after the mint has occured.
  constructor(
    string memory name,
    string memory symbol,
    uint256 treasurySupply,
    address treasuryAddr,
    uint256 bondSupply,
    address idolContract,
    address marketContract)
    ERC20(name, symbol)
  {
    bondedSteth = 0;
    bondCurve[0] = bondSlice({start_x:0,slope:-228248550476,intercept:75000000000000000000000000});
    bondCurve[1] = bondSlice({start_x:25000000000000000000000,slope:-210882750211,intercept:74565854993372400000000000});
    bondCurve[2] = bondSlice({start_x:50000000000000000000000,slope:-194838189526,intercept:73763626959115100000000000});
    bondCurve[3] = bondSlice({start_x:75000000000000000000000,slope:-180014344747,intercept:72651838600692400000000000});
    bondCurve[4] = bondSlice({start_x:100000000000000000000000,slope:-159991353646,intercept:70649539490591900000000000});
    bondCurve[5] = bondSlice({start_x:150000000000000000000000,slope:-136572283238,intercept:67136678929379100000000000});
    bondCurve[6] = bondSlice({start_x:200000000000000000000000,slope:-116581228446,intercept:63138467970989800000000000});
    bondCurve[7] = bondSlice({start_x:250000000000000000000000,slope:-95780563826,intercept:57938301816001500000000000});
    bondCurve[8] = bondSlice({start_x:325000000000000000000000,slope:-75539912086,intercept:51360090000505800000000000});
    bondCurve[9] = bondSlice({start_x:400000000000000000000000,slope:-57369920299,intercept:44092093285737000000000000});
    bondCurve[10] = bondSlice({start_x:500000000000000000000000,slope:-40276389676,intercept:35545327974265900000000000});
    bondCurve[11] = bondSlice({start_x:625000000000000000000000,slope:-27115378872,intercept:27319696221780300000000000});
    bondCurve[12] = bondSlice({start_x:750000000000000000000000,slope:-18254957241,intercept:20674379998547900000000000});
    bondCurve[13] = bondSlice({start_x:875000000000000000000000,slope:-12289832477,intercept:15454895830019000000000000});
    bondCurve[14] = bondSlice({start_x:1000000000000000000000000,slope:-6922093002,intercept:10087156355048300000000000});
    bondCurve[15] = bondSlice({start_x:1250000000000000000000000,slope:-3137384279,intercept:5356270451292460000000000});
    bondCurve[16] = bondSlice({start_x:1500000000000000000000000,slope:-622755295,intercept:1584326975368420000000000});
    bondCurve[17] = bondSlice({start_x:2500000000000000000000000,slope:-27508,intercept:27507507410700400000000});
    bondCurve[18] = bondSlice({start_x:250000000000000000000000000,slope:0,intercept:0});
    _mint(treasuryAddr, treasurySupply);
    _mint(idolContract, bondSupply);
    idolMainAddress = idolContract;
    idolMarketAddress = marketContract;
  }

  /**
    @notice transferFrom overrides ERC20's transferFrom function. It is written so that the
      marketplace contract automatically has approval to transfer VIRTUE for other addresses.
  */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {

    // Automatically give the marketplace approval to transfer VIRTUE to save the user gas fees spent
    // on approval.
    if (msg.sender == idolMarketAddress){
      _transfer(sender, recipient, amount);
      return true;
    }
    else {
      return super.transferFrom(sender, recipient, amount);
    }
  }

  /**
    @notice virtueBondCum is a helper function for getVirtueBondAmt. This function takes
      an amount of stETH (_stethAmt) as input and returns the cumulative amount
      of VIRTUE remaining in the bonding curve if the treasury had _stethAmt of Steth.
  */
  function virtueBondCum(uint _stethAmt)
    public
    view
    returns (uint)
  {
    uint index;
    for (index = 0; index <= 18; index++) {
      if(bondCurve[index].start_x > _stethAmt){
        break;
      }
    }
    require(index > 0, "Amount is below the start of the Bonding Curve");
    int current_slope = bondCurve[index-1].slope;
    int current_int = bondCurve[index-1].intercept;

    return uint(int(_stethAmt) * current_slope / (10**9) + current_int);
  }

  /**
    @notice incrementBondedSteth updates the bondedSteth variable -- only the idol main contract
      is allowed to call it.
  */
  function incrementBondedSteth(uint256 _incAmt)
    external
    onlyIdolMain
  {
    bondedSteth = bondedSteth + _incAmt;
  }

  /**
    @notice getVirtueBondAmt takes an amount of stETH as input and returns the amount of VIRTUE that the
      bonding curve is currently offering in exchange for that amount of stETH.
    @param _stethAmt - the amount of stETH that the user would like to exchange for VIRTUE via the
      bonding curve.
    @return (uint256) the amount of VIRTUE that the user would receive if they deposited the specified
      amount of stETH the bonding curve at this moment.
  */
  function getVirtueBondAmt(uint256 _stethAmt)
    public
    view
    returns (uint256)
  {
    return virtueBondCum(bondedSteth) - virtueBondCum(bondedSteth + _stethAmt);
  }

  modifier onlyIdolMain {
    require(msg.sender == idolMainAddress, "Function can only be called by IdolMain");
    _;
  }
}