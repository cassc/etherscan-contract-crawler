// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "../interfaces/ITokenMinter.sol";
import "../interfaces/IERC1155Mint.sol";
import "../interfaces/IPower.sol";

import "../diamond/LibAppStorage.sol";
import { LibDiamond } from "../diamond/LibDiamond.sol";

interface ITokenAttributeSetter {
    function setAttribute(
        uint256 _tokenId,
        string memory key,
        uint256 value
    ) external;
}

contract TokenMinterFacet is IERC1155Mint, IPower {

    // application storage
    AppStorage internal s;

    event Token(address indexed receiver, uint256 indexed tokenId);
    event TokenBurn(address indexed target, uint256 indexed tokenId);

    constructor() {
        s.tokenMinterStorage._tokenCounter = 1;
    }

    modifier onlyController {
        require(msg.sender == LibDiamond.contractOwner()  || msg.sender == address(this), "only the contract owner can mint");
        _;
    }

    function setToken(address token) external onlyController {
        s.tokenMinterStorage.token = token;
    }

    /// @notice mint a token associated with a collection with an amount
    /// @param target the mint receiver
    /// @param id the collection id
    function burn(address target, uint256 id) external onlyController {

        delete s.tokenMinterStorage._tokenMinters[id];

        // burn the token
        IERC1155Burn(s.tokenMinterStorage.token).burn(target, id, 1);

        // emit the event
        emit TokenBurn(target, id);
    }

    function mint(
        uint256,
        uint256,
        bytes memory
    ) external override onlyController returns (uint256 idOut) {
        idOut = uint256(_mint(msg.sender));
    }

    function mintTo(
        address recipient,
        uint256,
        uint256,
        bytes memory
    ) external override onlyController returns (uint256 idOut) {
        idOut = uint256(_mint(recipient));
    }

    function _mint(address receiver) internal returns(bytes32 publicHash)  {

        // require receiver not be the zero address
        require(receiver != address(0x0), "receiver cannot be the zero address");

        // create a keccak256 hash using the contract address, the collection, and the gia number
        publicHash = bytes32(s.tokenMinterStorage._tokenCounter++);

        // store the audit hash
        s.tokenMinterStorage._tokenMinters[uint256(publicHash)] = msg.sender;
        uint256 pHash =  uint256(publicHash);

        ITokenAttributeSetter(address(this)).setAttribute(
            pHash,
            "Rarity",
            0
        );

        ITokenAttributeSetter(address(this)).setAttribute(
            pHash,
            "Type",
            0
        );

        ITokenAttributeSetter(address(this)).setAttribute(
            pHash,
            "Power",
            1
        );

        // mint the token to the receiver using the public hash
        IERC1155Mint(s.tokenMinterStorage.token).mintTo(
            receiver,
            pHash,
            1,
            ""
        );

        // emit the event
        emit Token(receiver, uint256(publicHash));

        // emit the first power updated
        emit PowerUpdated(pHash, 1);
    }

}