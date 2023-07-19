//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*

    ███████╗████████╗ █████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗
    ██╔════╝╚══██╔══╝██╔══██╗██║ ██╔╝██║████╗  ██║██╔════╝
    ███████╗   ██║   ███████║█████╔╝ ██║██╔██╗ ██║██║  ███╗
    ╚════██║   ██║   ██╔══██║██╔═██╗ ██║██║╚██╗██║██║   ██║
    ███████║   ██║   ██║  ██║██║  ██╗██║██║ ╚████║╚██████╔╝
    ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝

              Planktoons NFT staking contract
                  https://planktoons.io

*/

import {NFTStaking} from "./NFTStaking.sol";

contract PlanktoonsStaking is NFTStaking {
  string constant public name = "PlanktoonsStaking";
}