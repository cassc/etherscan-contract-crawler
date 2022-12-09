// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.15;
pragma abicoder v2;

interface OnlyBotsData {
    function getBuffer() external pure returns (bytes memory);

    function getBatchSize() external pure returns (uint256);

    function getPrice() external pure returns (uint256);
}

struct DataContract {
    OnlyBotsData dataContract;
    uint256 size;
    uint256 price;
    string cid;
}

interface OnlyBotsDeserializer {
    function deserialize(
        DataContract memory _contract,
        uint256 _batchIndex,
        uint128 _botId
    ) external pure returns (string memory);
}
