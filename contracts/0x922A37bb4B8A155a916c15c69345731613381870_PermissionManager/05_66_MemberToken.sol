pragma solidity ^0.8.7;

/* solhint-disable indent */

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "./interfaces/IControllerRegistry.sol";
import "./interfaces/IControllerBase.sol";

contract MemberToken is ERC1155Supply, Ownable {
    using Address for address;

    IControllerRegistry public controllerRegistry;

    mapping(uint256 => address) public memberController;

    uint256 public nextAvailablePodId = 0;
    string public _contractURI =
        "https://orcaprotocol-nft.vercel.app/assets/contract-metadata";

    event MigrateMemberController(uint256 podId, address newController);

    /**
     * @param _controllerRegistry The address of the ControllerRegistry contract
     */
    constructor(address _controllerRegistry, string memory uri) ERC1155(uri) {
        require(_controllerRegistry != address(0), "Invalid address");
        controllerRegistry = IControllerRegistry(_controllerRegistry);
    }

    // Provides metadata value for the opensea wallet. Must be set at construct time
    // Source: https://www.reddit.com/r/ethdev/comments/q4j5bf/contracturi_not_reflected_in_opensea/
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    // Note that OpenSea does not currently update contract metadata when this value is changed. - Nov 2021
    function setContractURI(string memory newContractURI) public onlyOwner {
        _contractURI = newContractURI;
    }

    /**
     * @param _podId The pod id number
     * @param _newController The address of the new controller
     */
    function migrateMemberController(uint256 _podId, address _newController)
        external
    {
        require(_newController != address(0), "Invalid address");
        require(
            msg.sender == memberController[_podId],
            "Invalid migrate controller"
        );
        require(
            controllerRegistry.isRegistered(_newController),
            "Controller not registered"
        );

        memberController[_podId] = _newController;
        emit MigrateMemberController(_podId, _newController);
    }

    function getNextAvailablePodId() external view returns (uint256) {
        return nextAvailablePodId;
    }

    function setUri(string memory uri) external onlyOwner {
        _setURI(uri);
    }

    /**
     * @param _account The account address to assign the membership token to
     * @param _id The membership token id to mint
     * @param data Passes a flag for initial creation event
     */
    function mint(
        address _account,
        uint256 _id,
        bytes memory data
    ) external {
        _mint(_account, _id, 1, data);
    }

    /**
     * @param _accounts The account addresses to assign the membership tokens to
     * @param _id The membership token id to mint
     * @param data Passes a flag for an initial creation event
     */
    function mintSingleBatch(
        address[] memory _accounts,
        uint256 _id,
        bytes memory data
    ) public {
        for (uint256 index = 0; index < _accounts.length; index += 1) {
            _mint(_accounts[index], _id, 1, data);
        }
    }

    /**
     * @param _accounts The account addresses to burn the membership tokens from
     * @param _id The membership token id to burn
     */
    function burnSingleBatch(address[] memory _accounts, uint256 _id) public {
        for (uint256 index = 0; index < _accounts.length; index += 1) {
            _burn(_accounts[index], _id, 1);
        }
    }

    function createPod(address[] memory _accounts, bytes memory data)
        external
        returns (uint256)
    {
        uint256 id = nextAvailablePodId;
        nextAvailablePodId += 1;

        require(
            controllerRegistry.isRegistered(msg.sender),
            "Controller not registered"
        );

        memberController[id] = msg.sender;

        if (_accounts.length != 0) {
            mintSingleBatch(_accounts, id, data);
        }

        return id;
    }

    /**
     * @param _account The account address holding the membership token to destroy
     * @param _id The id of the membership token to destroy
     */
    function burn(address _account, uint256 _id) external {
        _burn(_account, _id, 1);
    }

    // this hook gets called before every token event including mint and burn
    /**
     * @param operator The account address that initiated the action
     * @param from The account address recieveing the membership token
     * @param to The account address sending the membership token
     * @param ids An array of membership token ids to be transfered
     * @param amounts The amount of each membership token type to transfer
     * @param data Passes a flag for an initial creation event
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override {
        // use first id to lookup controller
        address controller = memberController[ids[0]];
        require(controller != address(0), "Pod doesn't exist");

        for (uint256 i = 0; i < ids.length; i += 1) {
            // check if recipient is already member
            if (to != address(0)) {
                require(balanceOf(to, ids[i]) == 0, "User is already member");
            }
            // verify all ids use same controller
            require(
                memberController[ids[i]] == controller,
                "Ids have different controllers"
            );
        }

        // perform orca token transfer validations
        IControllerBase(controller).beforeTokenTransfer(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }
}