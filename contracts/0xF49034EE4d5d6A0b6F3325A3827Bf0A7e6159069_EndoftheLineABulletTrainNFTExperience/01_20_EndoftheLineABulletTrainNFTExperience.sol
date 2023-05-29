// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../../NiftysERC721A.sol';
import '../../utils/NiftysDefaultOperators.sol';

/**
  _____           _        __ _   _          _     _               _    ____        _ _      _  _____          _       _   _ _____ _____ _____                      _                     
 | ____|_ __   __| | ___  / _| |_| |__   ___| |   (_)_ __   ___   / \  | __ ) _   _| | | ___| ||_   _| __ __ _(_)_ __ | \ | |  ___|_   _| ____|_  ___ __   ___ _ __(_) ___ _ __   ___ ___ 
 |  _| | '_ \ / _` |/ _ \| |_| __| '_ \ / _ \ |   | | '_ \ / _ \ / _ \ |  _ \| | | | | |/ _ \ __|| || '__/ _` | | '_ \|  \| | |_    | | |  _| \ \/ / '_ \ / _ \ '__| |/ _ \ '_ \ / __/ _ \
 | |___| | | | (_| | (_) |  _| |_| | | |  __/ |___| | | | |  __// ___ \| |_) | |_| | | |  __/ |_ | || | | (_| | | | | | |\  |  _|   | | | |___ >  <| |_) |  __/ |  | |  __/ | | | (_|  __/
 |_____|_| |_|\__,_|\___/|_|  \__|_| |_|\___|_____|_|_| |_|\___/_/   \_\____/ \__,_|_|_|\___|\__||_||_|  \__,_|_|_| |_|_| \_|_|     |_| |_____/_/\_\ .__/ \___|_|  |_|\___|_| |_|\___\___|
                                                                                                                                                   |_|=                                    
*/

contract EndoftheLineABulletTrainNFTExperience is NiftysERC721A, NiftysDefaultOperators {
    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        address recipient,
        uint24 value,
        address admin,
        address operator,
        address relay
    ) NiftysERC721A(name, symbol, baseURI, baseURI, recipient, value, admin) {
        _setupDefaultOperator(operator);
        grantRole(MINTER, relay);
    }

    function globalRevokeDefaultOperator() public isAdmin {
        _globalRevokeDefaultOperator();
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        override(ERC721A)
        returns (bool)
    {
        return (isDefaultOperatorFor(owner, operator) || super.isApprovedForAll(owner, operator));
    }
}