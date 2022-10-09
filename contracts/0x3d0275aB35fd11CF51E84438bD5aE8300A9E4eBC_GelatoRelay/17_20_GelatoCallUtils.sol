// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {GelatoBytes} from "./GelatoBytes.sol";

library GelatoCallUtils {
    using GelatoBytes for bytes;

    function revertingContractCall(
        address _contract,
        bytes memory _data,
        string memory _errorMsg
    ) internal returns (bytes memory returndata) {
        bool success;
        (success, returndata) = _contract.call(_data);

        // solhint-disable-next-line max-line-length
        // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/f9b6fc3fdab7aca33a9cfa8837c5cd7f67e176be/contracts/utils/AddressUpgradeable.sol#L177
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(
                    isContract(_contract),
                    string(abi.encodePacked(_errorMsg, "Call to non contract"))
                );
            }
        } else {
            returndata.revertWithError(_errorMsg);
        }
    }

    // solhint-disable-next-line max-line-length
    // https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/f9b6fc3fdab7aca33a9cfa8837c5cd7f67e176be/contracts/utils/AddressUpgradeable.sol#L36
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
}