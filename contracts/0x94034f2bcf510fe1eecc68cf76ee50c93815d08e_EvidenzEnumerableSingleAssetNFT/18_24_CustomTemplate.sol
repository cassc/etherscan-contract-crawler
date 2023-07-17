// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

import {Environment} from '../utils/Environment.sol';

abstract contract CustomTemplate is Ownable {
    Template public template;

    struct Template {
        string id;
        string value;
        string metadata;
        Environment.Endpoint reader;
        Environment.Endpoint toolbox;
    }

    function setTemplate(Template calldata template_) external onlyOwner {
        template = template_;
    }

    function getTemplate() external view returns (Template memory) {
        return template;
    }
}