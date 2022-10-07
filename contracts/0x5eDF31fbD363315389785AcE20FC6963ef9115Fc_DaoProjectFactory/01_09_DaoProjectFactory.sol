// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DaoProjectToken} from "./DaoProjectToken.sol";
import {IERC20Project} from "./interfaces/IERC20Project.sol";
import {Pausable} from "../../Pausable.sol";

/**
 * @author MetaPlayerOne DAO
 * @title DaoProjectFactory
 * @notice Contract which manages daos' projects in MetaPlayerOne.
 */
contract DaoProjectFactory is Pausable {
    enum Type { GAME, META, DEFI, PROTOCOL }
    struct Metadata { string project_title; string project_description; string project_banner; string project_logo; }
    struct Project { string project_title; string project_description; string project_banner; string project_logo; string name; string symbol; address owner_of; uint256 utlimate_supply; address access_token; address token_address; address dao_address; Type token_type; uint256 join_fee; uint256 price; }

    mapping(address => Project) private _project_by_address;
    mapping(address => bool) private _is_activated;

    /**
     * @dev setup owner of this contract.
     */
    constructor(address owner_of_) Pausable(owner_of_) {}

    /**
     * @dev emits after new project has been created/added to MetaPlayerOne dao.
     */
    event projectCreated(Project project);
    
    /**
     * @dev a function that triggers the creation of a project for dao.
     * @param metadata wraps all project metadata (such as title, description, logo).
     * @param name name of the token to be created.
     * @param symbol symbol of the token to be created.
     * @param token_type includes values: 0, 1, 2, 3. 0 - `game`, 1 - `meta`, 2 - `defi`, 3 - `protocol`.
     * @param join_fee the minimum threshold of tokens for the entered project.
     * @param ultimate_supply the maximum number of tokens that can be.
     * @param access_token access token address.
     * @param dao_address dao address.
     * @param price price for 1 ERC20 token.
     */
    function createProject(Metadata memory metadata, string memory name, string memory symbol, Type token_type, uint256 join_fee, uint256 ultimate_supply, address access_token, address dao_address, uint256 price) public notPaused {
        DaoProjectToken token = new DaoProjectToken(name, symbol, access_token, ultimate_supply, msg.sender, price);
        address token_address = address(token);
        _project_by_address[token_address] = Project(metadata.project_title, metadata.project_description, metadata.project_banner, metadata.project_logo, name, symbol, msg.sender, ultimate_supply, access_token, token_address, dao_address, token_type, join_fee, price);
        _is_activated[token_address] = true;
        emit projectCreated(_project_by_address[token_address]);
    }

    /**
     * @dev function that triggers the addition of a project for a dao.
     * @param metadata wraps all project metadata (such as title, description, logo).
     * @param token_address address of ERC20 token.
     * @param ultimate_supply the maximum number of tokens that can be.
     * @param token_type includes values: 0, 1, 2, 3. 0 - `game`, 1 - `meta`, 2 - `defi`, 3 - `protocol`.
     * @param join_fee the minimum threshold of tokens for the entered project.
     * @param access_token access token address.
     * @param dao_address dao address.
     * @param price price for 1 ERC20 token.
     */
    function addProject(Metadata memory metadata, address token_address, uint256 ultimate_supply, address access_token, address dao_address, Type token_type, uint256 join_fee, uint256 price) public notPaused {
        require(!_is_activated[token_address], "Project is already activated");
        IERC20Project token = IERC20Project(token_address);
        try token.price() { price = token.price(); } catch {}
        try token.ultimate_supply() { ultimate_supply = token.ultimate_supply(); } catch {}
        try token.access_token() { access_token = token.access_token(); } catch {}
        _project_by_address[token_address] = Project(metadata.project_title, metadata.project_description, metadata.project_banner, metadata.project_logo, token.name(), token.symbol(), msg.sender, ultimate_supply, access_token, token_address, dao_address, token_type, join_fee, price);
        _is_activated[token_address] = true;
        emit projectCreated(_project_by_address[token_address]);
    }
}