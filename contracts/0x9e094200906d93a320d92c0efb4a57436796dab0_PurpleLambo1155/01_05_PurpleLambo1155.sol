// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC1155} from "solmate/tokens/ERC1155.sol";
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {Base64} from "openzeppelin/utils/Base64.sol";

/*
    ____                   __        __                    __        
   / __ \__  ___________  / /__     / /   ____ _____ ___  / /_  ____ 
  / /_/ / / / / ___/ __ \/ / _ \   / /   / __ `/ __ `__ \/ __ \/ __ \
 / ____/ /_/ / /  / /_/ / /  __/  / /___/ /_/ / / / / / / /_/ / /_/ /
/_/    \__,_/_/  / .___/_/\___/  /_____/\__,_/_/ /_/ /_/_.___/\____/ 
                /_/                                                  
*/

contract PurpleLambo1155 is ERC1155, Ownable {
    uint256 max = 20_000;
    uint256 public totalSupply;

    error AmountExceedsLimit();
    error AmountExceedsMaxSupply();

    function uri(uint256 tokenId) public view override returns (string memory) {
        if (tokenId == 1) {
            bytes memory dataURI = abi.encodePacked(
                '{"name":"Purple Lambo","image":"https://arweave.net/tovQ6c5iuKah_wfPwGQT8W1m272C0O10uiuB0KFKEJo","description":"no dev just lambo. https://t.me/purplelamboerc20 https://etherscan.io/token/0xDF90124B8a10d52a5Df27d3f61f94F44ADe09f12"}'
            );

            return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
        }
        return "";
    }

    function contractURI() public view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            '{"name":"Purple Lambo","image":"https://arweave.net/tovQ6c5iuKah_wfPwGQT8W1m272C0O10uiuB0KFKEJo","description":"no dev just lambo. https://t.me/purplelamboerc20 https://etherscan.io/token/0xDF90124B8a10d52a5Df27d3f61f94F44ADe09f12"}'
        );

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(dataURI)));
    }

    function mint(uint256 amount) public {
        if (amount > 10) {
            revert AmountExceedsLimit();
        }
        if (totalSupply + amount > max) {
            revert AmountExceedsMaxSupply();
        }
        totalSupply += amount;
        _mint(msg.sender, 1, amount, "");
    }
}