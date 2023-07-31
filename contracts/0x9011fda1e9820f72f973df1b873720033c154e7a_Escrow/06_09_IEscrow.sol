// SPDX-License-Identifier: UNLICENSED
/*
Copyright (C) 2023 MC² Finance

All rights reserved. This program and the accompanying materials
are made available for use and disclosure in accordance with the terms of this copyright notice.
This notice does not constitute a license agreement. No part of this program may be used, reproduced, 
or transmitted in any form or by any means, electronic, mechanical, photocopying, recording, or otherwise, 
without the prior written permission of MC² Finance.
*/

pragma solidity ^0.8.0;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IEscrow {
    event TransferTokenTo(
        address indexed sender,
        address indexed recipient,
        IERC20 indexed token,
        uint256 amount
    );

    /**
     * @dev Transfer funds to a recipient.
     *
     * - MUST emit TransferTokenTo event.
     */
    function transferTokenTo(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external;
}