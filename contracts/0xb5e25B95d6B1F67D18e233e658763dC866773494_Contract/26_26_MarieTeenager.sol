// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@thirdweb-dev/contracts/base/ERC721Base.sol";
import "@thirdweb-dev/contracts/extension/PrimarySale.sol";
import "@thirdweb-dev/contracts/extension/PlatformFee.sol";
contract Contract is ERC721Base,PrimarySale,PlatformFee {
    address public deployer;

      constructor(
        string memory _name,
        string memory _symbol,
        address _royaltyRecipient,
        uint128 _royaltyBps
    )
        ERC721Base(
            _name,
            _symbol,
            _royaltyRecipient,
            _royaltyBps
        )
    {
        deployer = msg.sender;
    }

            function _canSetPrimarySaleRecipient()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == deployer;
    }

        function _canSetPlatformFeeInfo() internal view virtual override returns (bool) {
        return msg.sender == deployer;
    }

}