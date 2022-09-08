// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "./BaseEnigmaNFT1155.sol";

/// @title EnigmaUserToken1155
///
/// @dev This contract extends from BaseEnigmaNFT1155

contract EnigmaUserToken1155 is BaseEnigmaNFT1155 {
    address public operator;
    bool public autoId;

    event OperatorChanged(address indexed newOperator);

    struct BatchMintItem {
        uint256 tokenId;
        address recipient;
        uint256 amount;
        uint256 fee;
        string uri;
    }

    modifier onlyOwnerOrOperator() {
        require(msg.sender == owner() || msg.sender == operator, "Not owner nor operator");
        _;
    }

    /// oz-upgrades-unsafe-allow constructor
    // solhint-disable-next-line
    constructor() initializer {}

    /**
     * @notice Initialize NFT1155 contract.
     *
     * @param name_ the token name
     * @param symbol_ the token symbol
     * @param tokenURIPrefix_ the token base uri
     * @param operator_ that will be able to mint tokens on behalf the owner
     */
    function initialize(
        string memory name_,
        string memory symbol_,
        string memory tokenURIPrefix_,
        address operator_,
        address transferGatekeeperBeacon_,
        bool autoId_
    ) external initializer {
        super._initialize(name_, symbol_, tokenURIPrefix_);
        operator = operator_;
        transferGatekeeperBeacon = IBeacon(transferGatekeeperBeacon_);
        autoId = autoId_;
    }

    function batchMint(BatchMintItem[] calldata toMint) external onlyOwnerOrOperator {
        uint256 length = toMint.length;

        BatchMintItem calldata item;
        uint256 tokenId;
        for (uint256 index = 0; index < length; index++) {
            item = toMint[index];
            tokenId = item.tokenId;
            if (!super._exists(item.tokenId)) {
                super._mintNew(item.recipient, autoId ? _increaseNextId() : tokenId, item.amount, item.uri, item.fee);
            } else {
                super._mint(item.recipient, tokenId, item.amount, "");
            }
        }
    }

    /**
     * @notice For compatibility reasons this method is kept although it always returns the contract owner
     */
    function getCreator(uint256) external view virtual override returns (address) {
        return owner();
    }

    /**
     * @notice Let's the owner to update the operator
     * @param newOperator to set
     */
    function setOperator(address newOperator) external onlyOwner {
        operator = newOperator;
        emit OperatorChanged(newOperator);
    }
}