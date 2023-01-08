// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

import "./NFTToken.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract Nflow {
    address implementation;

    mapping(address => uint256[]) public erc721TokenIds;

    using Address for address;

    constructor() {
        implementation = address(new NFTToken());
    }

    function tokenAddress(address _erc721) public view returns (address) {
        bytes32 salt = keccak256(abi.encodePacked(_erc721));
        return
            Clones.predictDeterministicAddress(
                implementation,
                salt,
                address(this)
            );
    }

    function createToken(address _erc721) private {
        bytes32 salt = keccak256(abi.encodePacked(_erc721));
        address token = Clones.cloneDeterministic(implementation, salt);
        NFTToken(token).initialize(
            string(abi.encodePacked(IERC721Metadata(_erc721).name(), " Token")),
            string(
                abi.encodePacked(IERC721Metadata(_erc721).symbol(), " Token")
            )
        );
    }

    function tokenization(
        address _erc721,
        uint256[] calldata _erc721TokenIds
    ) external {
        uint256 _erc721Amount = _erc721TokenIds.length;
        require(_erc721Amount > 0, "_erc721Amount must greater than zero");

        address token = tokenAddress(_erc721);
        if (!token.isContract()) {
            createToken(_erc721);
        }

        for (uint256 i = 0; i < _erc721Amount; i++) {
            IERC721Metadata(_erc721).transferFrom(
                msg.sender,
                address(this),
                _erc721TokenIds[i]
            );
            erc721TokenIds[_erc721].push(_erc721TokenIds[i]);
        }

        NFTToken(token).mint(msg.sender, _erc721Amount * 1e36);
    }

    function nftization(address _erc721, uint256 _erc20Amount) external {
        require(
            _erc20Amount >= 1e36,
            "_erc20Amount must greater or equal than 1e36"
        );

        address token = tokenAddress(_erc721);
        NFTToken(token).burnFrom(msg.sender, _erc20Amount);
        uint256 erc721Amount = _erc20Amount / 1e36;
        for (uint256 i = 0; i < erc721Amount; i++) {
            IERC721Metadata(_erc721).transferFrom(
                address(this),
                msg.sender,
                erc721TokenIds[_erc721][i]
            );
            erc721TokenIds[_erc721][i] = erc721TokenIds[_erc721][
                erc721TokenIds[_erc721].length - 1 - i
            ];
        }

        for (uint256 i = 0; i < erc721Amount; i++) {
            erc721TokenIds[_erc721].pop();
        }
    }
}