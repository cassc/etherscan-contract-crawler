pragma solidity 0.8.3;

import "./ERC721LendingPool02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PoolHelper {
  struct LoanOption {
    address poolAddress;
    uint256 durationSeconds;
    uint32 interestBPS1000000XBlock;
    uint32 collateralFactorBPS;
  }

   uint256[7] tenors = [86400, 259200, 604800, 1209600, 2592000, 5184000, 7776000];

  function checkLoanOptions(address[] calldata addresses) external view returns (LoanOption[] memory) {
    uint256 addressesLength = addresses.length;
    LoanOption[] memory loanOptions = new LoanOption[](addressesLength*5);
    uint256 k;
    for (uint256 i; i < addressesLength; i++) {
      for (uint256 j; j<5; j++) {
        (uint32 a, uint32 b) = ERC721LendingPool02(addresses[i]).durationSeconds_poolParam(tenors[j]);
        if (b > 0) {
          loanOptions[k] = LoanOption(addresses[i], tenors[j], a, b);
          unchecked {
            ++k;
          }
        }
      }
    }
    return loanOptions;
  }

  function checkPoolValidity(address[] calldata addresses) external view returns (bool[] memory) {
    uint256 addressesLength = addresses.length;
    bool[] memory validities = new bool[](addressesLength);
    for (uint256 i; i < addressesLength; i++) {
      address fundSource = ERC721LendingPool02(addresses[i])._fundSource();
      validities[i] = (IERC20(ERC721LendingPool02(addresses[i])._supportedCurrency()).allowance(fundSource, addresses[i]) > 100000000000000000000);
    }
    return validities;
  }
}