// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IEthWormhole {
    function sendMessage(bytes calldata message_) external;
}

interface IExoAvatar {
    function upgradeAvatar(
        uint256 id,
        uint256 stat,
        uint256 value
    ) external;

    // returns owner, civLevel, attack, defense, reach, luck
    function getAvatar(uint256 id)
        external
        returns (
            uint256, // id
            bool, // is active
            address, // controller
            uint256, // level
            uint256 // health
        );

    function getAvatarStats(uint256 id)
        external
        returns (
            uint256, //attach base
            uint256, // attach boost
            uint256, //defense base
            uint256, // defense boost
            uint256, //reach base
            uint256, // reach boost
            uint256, //luck base
            uint256 //luck boost
        );

    function activateAvatars(address to, uint256[] memory planetIds) external;
}

interface IExoToken {
    function mint(address _to, uint256 _amount) external;

    function balanceOf(address _to) external returns (uint256);
}

interface IExoItems {
    function mintItem(address _to, uint256 _id) external returns (uint256);
}