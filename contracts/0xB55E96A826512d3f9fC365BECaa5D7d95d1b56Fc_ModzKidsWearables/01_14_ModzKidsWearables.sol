// SPDX-License-Identifier: UNLICENSED
//
//         ,----,
//       ,/   .`|       ,--,                            ____      ,----..                       ,----,
//     ,`   .'  :     ,--.'|    ,---,.                ,'  , `.   /   /   \      ,---,         .'   .`|
//   ;    ;     /  ,--,  | :  ,'  .' |             ,-+-,.' _ |  /   .     :   .'  .' `\    .'   .'   ;
// .'___,/    ,',---.'|  : ',---.'   |          ,-+-. ;   , || .   /   ;.  \,---.'     \ ,---, '    .'
// |    :     | |   | : _' ||   |   .'         ,--.'|'   |  ;|.   ;   /  ` ;|   |  .`\  ||   :     ./
// ;    |.';  ; :   : |.'  |:   :  |-,        |   |  ,', |  ':;   |  ; \ ; |:   : |  '  |;   | .'  /
// `----'  |  | |   ' '  ; ::   |  ;/|        |   | /  | |  |||   :  | ; | '|   ' '  ;  :`---' /  ;
//     '   :  ; '   |  .'. ||   :   .'        '   | :  | :  |,.   |  ' ' ' :'   | ;  .  |  /  ;  /
//     |   |  ' |   | :  | '|   |  |-,        ;   . |  ; |--' '   ;  \; /  ||   | :  |  ' ;  /  /--,
//     '   :  | '   : |  : ;'   :  ;/|        |   : |  | ,     \   \  ',  / '   : | /  ; /  /  / .`|
//     ;   |.'  |   | '  ,/ |   |    \        |   : '  |/       ;   :    /  |   | '` ,/./__;       :
//     '---'    ;   : ;--'  |   :   .'        ;   | |`-'         \   \ .'   ;   :  .'  |   :     .'
//              |   ,/      |   | ,'          |   ;/              `---`     |   ,.'    ;   |  .'
//              '---'       `----'            '---'                         '---'      `---'
//
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract ModzKidsWearables is ERC1155, AccessControl, Ownable, Pausable {
    bytes32 public constant URI_SETTER_ROLE = keccak256("URI_SETTER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct mintContractConfig {
        bool enabled;
        uint256 minTokenID;
        uint256 maxTokenID;
    }

    mapping(address => mintContractConfig) public mintContractConfigMapping;

    mapping(uint256 => uint256) private _totalSupply;
    uint256 private _totalSupplyAll;

    constructor()
        ERC1155("https://metadata.themodz.io/kids/wearables/{id}.json")
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(URI_SETTER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function setURI(string memory newuri) external onlyRole(URI_SETTER_ROLE) {
        _setURI(newuri);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    function addMinterContract(
        address minter,
        uint256 minTokenID,
        uint256 maxTokenID
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, minter);
        mintContractConfig memory contractConfig = mintContractConfig({
            enabled: true,
            minTokenID: minTokenID,
            maxTokenID: maxTokenID
        });
        mintContractConfigMapping[minter] = contractConfig;
    }

    function disableMinterContract(address minter)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _grantRole(MINTER_ROLE, minter);
        mintContractConfigMapping[minter].enabled = false;
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(
            id >= mintContractConfigMapping[msg.sender].minTokenID &&
                id <= mintContractConfigMapping[msg.sender].maxTokenID,
            "Invalid token id"
        );

        require(
            mintContractConfigMapping[msg.sender].enabled,
            "Disabled mint contract"
        );

        _mint(to, id, amount, "");
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external onlyRole(MINTER_ROLE) whenNotPaused {
        require(
            mintContractConfigMapping[msg.sender].enabled,
            "Disabled mint contract"
        );

        for (uint i = 0; i < ids.length; i++) {
            require(
                ids[i] >= mintContractConfigMapping[msg.sender].minTokenID &&
                    ids[i] <= mintContractConfigMapping[msg.sender].maxTokenID,
                "Invalid token ids"
            );
        }
        _mintBatch(to, ids, amounts, "");
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(account, ids, values);
    }

    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function totalSupply() public view virtual returns (uint256) {
        return _totalSupplyAll;
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return totalSupply(id) > 0;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
                _totalSupplyAll += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
                _totalSupplyAll -= amounts[i];
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}