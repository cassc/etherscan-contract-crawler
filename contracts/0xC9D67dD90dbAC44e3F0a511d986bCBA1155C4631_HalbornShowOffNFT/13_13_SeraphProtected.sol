// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.5.0 <=0.9.0;

interface ISeraph {
    function checkEnter(address, bytes4, bytes calldata, uint256) external;
    function checkLeave(bytes4) external;
}

abstract contract SeraphProtected {

    ISeraph constant public seraph = ISeraph(0xAac09eEdCcf664a9A6a594Fc527A0A4eC6cc2788);

    modifier withSeraph() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, 0);
        _;
        seraph.checkLeave(msg.sig);
    }

    modifier withSeraphPayable() {
        seraph.checkEnter(msg.sender, msg.sig, msg.data, msg.value);
        _;
        seraph.checkLeave(msg.sig);
    }
}