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

interface IStrategyPoolHerald {
    event Redeem(
        address indexed strategyPool,
        address indexed owner,
        address indexed receiver,
        uint256 amount
    );

    /**
     * @dev Emits a Redeem event.
     */
    function proclaimRedeem(
        address owner,
        address receiver,
        uint256 amount
    ) external;
}