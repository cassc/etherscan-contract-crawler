// SPDX-License-Identifier: MIT
// Creator: twitter.com/0xNox_ETH

//               .;::::::::::::::::::::::::::::::;.
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX;
//               ;KNNNWMMWMMMMMMWWNNNNNNNNNWMMMMMN:
//                .',oXMMMMMMMNk:''''''''';OMMMMMN:
//                 ,xNMMMMMMNk;            l00000k,
//               .lNMMMMMMNk;               .....
//                'dXMMWNO;                .......
//                  'd0k;.                .dXXXXX0;
//               .,;;:lc;;;;;;;;;;;;;;;;;;c0MMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWX:
//               .,;,;;;;;;;;;;;;;;;;;;;;;;;,;;,;,.
//               'dkxkkxxkkkkkkkkkkkkkkkkkkxxxkxkd'
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               ;XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN:
//               'xkkkOOkkkkkkkkkkkkkkkkkkkkkkkkkx'
//                          .,,,,,,,,,,,,,,,,,,,,,.
//                        .lKNWWWWWWWWWWWWWWWWWWWX;
//                      .lKWMMMMMMMMMMMMMMMMMMMMMX;
//                    .lKWMMMMMMMMMMMMMMMMMMMMMMMN:
//                  .lKWMMMMMWKo:::::::::::::::::;.
//                .lKWMMMMMWKl.
//               .lNMMMMMWKl.
//                 ;kNMWKl.
//                   ;dl.
//
//               We vow to Protect
//               Against the powers of Darkness
//               To rain down Justice
//               Against all who seek to cause Harm
//               To heed the call of those in Need
//               To offer up our Arms
//               In body and name we give our Code
//
//               FOR THE BLOCKCHAIN ⚔️

pragma solidity ^0.8.17;

import "./ICloneforceClaimable.sol";
import "./Strings.sol";
import "./UpdatableOperatorFilterer.sol";
import "./RevokableDefaultOperatorFilterer.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract VoidReward is
    ERC1155Supply,
    RevokableDefaultOperatorFilterer,
    Ownable,
    ReentrancyGuard,
    ICloneforceClaimable
{
    address private _airdropManagerContract;
    string private _baseTokenURI;
    address private _admin;
    mapping(address => bool) private _burnAuthorizedContracts;

    bool public contractPaused;

    constructor(
        string memory baseTokenURI,
        address sigKey,
        address admin,
        address airdropManagerContract
    ) ERC1155("") {
        _admin = admin;
        _sigKey = sigKey;
        _baseTokenURI = baseTokenURI;
        _airdropManagerContract = airdropManagerContract;
        _mint(msg.sender, 1, 1, "");
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner() || msg.sender == _admin, "Not owner or admin");
        _;
    }

    // For airdrops and claiming through the airdrop manager contract
    function mintClaim(address to, uint256 tokenId, uint256 count) external override {
        require(msg.sender == _airdropManagerContract, "You cannot call this function");
        _mint(to, tokenId, count, "");
    }

    function uri(uint256 _id) public view virtual override returns (string memory) {
        return string.concat(_baseTokenURI, Strings.toString(_id));
    }

    function setAirdropManagerContract(address airdropManagerContract) external onlyOwnerOrAdmin {
        _airdropManagerContract = airdropManagerContract;
    }

    function mint(address to, uint256 tokenId, uint256 count) external onlyOwnerOrAdmin {
        _mint(to, tokenId, count, "");
    }

    function mintBatch(
        address[] calldata to,
        uint256 tokenId,
        uint256[] calldata counts
    ) external onlyOwnerOrAdmin {
        unchecked {
            for (uint256 i = 0; i < to.length; i++) {
                _mint(to[i], tokenId, counts[i], "");
            }
        }
    }

    function pauseContract(bool paused) external onlyOwnerOrAdmin {
        contractPaused = paused;
    }

    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
        require(!contractPaused, "Contract is paused");
    }

    // Burn functions

    function burn(address from, uint256 id, uint256 amount) external virtual {
        require(
            _burnAuthorizedContracts[msg.sender] ||
                from == msg.sender ||
                isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burn(from, id, amount);
    }

    function burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) external virtual {
        require(
            _burnAuthorizedContracts[msg.sender] ||
                from == msg.sender ||
                isApprovedForAll(from, msg.sender),
            "ERC1155: caller is not token owner nor approved"
        );

        _burnBatch(from, ids, amounts);
    }

    function setBurnAuthorizedContract(
        address authorizedContract,
        bool isAuthorized
    ) external onlyOwnerOrAdmin {
        _burnAuthorizedContracts[authorizedContract] = isAuthorized;
    }

    // Claim logic
    address private _sigKey;
    mapping(string => bool) private _usedNonces;

    function _claimTokens(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        string calldata nonce,
        bytes memory signature
    ) private {
        require(!_usedNonces[nonce], "Nonce already used");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(to, tokenId, amount, price, nonce))
            )
        );
        require(ecrecover(_hash, v, r, s) == _sigKey, "Invalid signature");

        // mint the tokens
        _usedNonces[nonce] = true;
        _mint(to, tokenId, amount, "");
    }

    function claimTokens(
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        string calldata nonce,
        bytes memory signature
    ) external payable nonReentrant {
        _claimTokens(to, tokenId, amount, price, nonce, signature);

        // check if the price is correct
        if (price > 0) {
            require(msg.value >= price, "Insufficient funds");
        }

        // refund excess ETH
        if (msg.value - price > 0.0001 ether) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function claimTokensBatch(
        address[] calldata to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256[] calldata prices,
        string[] calldata nonces,
        bytes[] memory signatures
    ) external payable nonReentrant {
        require(to.length == tokenIds.length, "Invalid input");
        require(to.length == amounts.length, "Invalid input");
        require(to.length == prices.length, "Invalid input");
        require(to.length == nonces.length, "Invalid input");
        require(to.length == signatures.length, "Invalid input");

        uint256 totalPrice = 0;
        for (uint256 i = 0; i < to.length; i++) {
            _claimTokens(to[i], tokenIds[i], amounts[i], prices[i], nonces[i], signatures[i]);
            totalPrice += prices[i];
        }

        // check if the price is correct
        if (totalPrice > 0) {
            require(msg.value >= totalPrice, "Insufficient funds");
        }

        // refund excess ETH
        if (msg.value - totalPrice > 0.0001 ether) {
            payable(msg.sender).transfer(msg.value - totalPrice);
        }
    }

    function areNoncesUsed(string[] calldata nonces) external view returns (bool[] memory) {
        bool[] memory isUsed = new bool[](nonces.length);
        for (uint256 i = 0; i < nonces.length; i++) {
            isUsed[i] = _usedNonces[nonces[i]];
        }
        return isUsed;
    }

    function setSignatureKey(address sigKey) external onlyOwner {
        _sigKey = sigKey;
    }

    // Burn upgrade logic
    mapping(uint256 => BurnUpgradeConfig) private _burnUpgradeConfigs;

    function addBurnUpgradeConfig(
        uint256 id,
        uint256[] memory burnIds,
        uint256[] memory burnCounts,
        uint256[] memory targetIds,
        uint256[] memory targetCounts,
        uint256 price
    ) external onlyOwnerOrAdmin {
        require(burnIds.length == burnCounts.length, "Burn ids and counts must be same length");
        require(
            targetIds.length == targetCounts.length,
            "Target ids and counts must be same length"
        );

        _burnUpgradeConfigs[id] = BurnUpgradeConfig({
            id: id,
            burnIds: burnIds,
            burnCounts: burnCounts,
            targetIds: targetIds,
            targetCounts: targetCounts,
            price: price
        });
    }

    function removeBurnUpgradeConfig(uint256 id) external onlyOwnerOrAdmin {
        delete _burnUpgradeConfigs[id];
    }

    function getBurnUpgradeConfig(
        uint256 configId
    )
        external
        view
        returns (
            uint256 id,
            uint256[] memory burnIds,
            uint256[] memory burnCounts,
            uint256[] memory targetIds,
            uint256[] memory targetCounts,
            uint256 price
        )
    {
        BurnUpgradeConfig memory config = _burnUpgradeConfigs[configId];
        return (
            config.id,
            config.burnIds,
            config.burnCounts,
            config.targetIds,
            config.targetCounts,
            config.price
        );
    }

    // Upgrade tokens by burning them and minting new ones
    function upgrade(uint256 burnUpgradeConfigId) external payable nonReentrant {
        BurnUpgradeConfig memory config = _burnUpgradeConfigs[burnUpgradeConfigId];
        require(config.id != 0, "Burn upgrade config not found");

        // check balance if there's a price
        require(msg.value >= config.price, "Insufficient funds");

        // burn and mint tokens
        _burnBatch(msg.sender, config.burnIds, config.burnCounts);
        _mintBatch(msg.sender, config.targetIds, config.targetCounts, "");

        // refund excess ETH
        if (msg.value - config.price > 0.0001 ether) {
            payable(msg.sender).transfer(msg.value - config.price);
        }
    }

    // Batch upgrade
    function upgradeBatch(uint256[] memory burnUpgradeConfigIds) external payable nonReentrant {
        uint256 totalCost = 0;
        for (uint256 i = 0; i < burnUpgradeConfigIds.length; i++) {
            BurnUpgradeConfig memory config = _burnUpgradeConfigs[burnUpgradeConfigIds[i]];
            require(config.id != 0, "Burn upgrade config not found");

            // burn and mint tokens
            _burnBatch(msg.sender, config.burnIds, config.burnCounts);
            _mintBatch(msg.sender, config.targetIds, config.targetCounts, "");

            // add to total cost
            totalCost += config.price;
        }

        // check balance if there's a price
        require(msg.value >= totalCost, "Insufficient funds");

        // refund excess ETH
        if (msg.value - totalCost > 0.0001 ether) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    // OpenSea metadata initialization
    function contractURI() public pure returns (string memory) {
        return "https://cloneforce.xyz/api/voidrewards/marketplace-metadata";
    }

    // OpenSea operator filtering
    function setApprovalForAll(
        address operator,
        bool approved
    ) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, amount, data);
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    function owner()
        public
        view
        virtual
        override(Ownable, UpdatableOperatorFilterer)
        returns (address)
    {
        return Ownable.owner();
    }

    // Withdraw ETH from contract
    function withdrawMoney(address to) external onlyOwnerOrAdmin {
        (bool success, ) = to.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}

struct BurnUpgradeConfig {
    uint256 id;
    uint256[] burnIds;
    uint256[] burnCounts;
    uint256[] targetIds;
    uint256[] targetCounts;
    uint256 price;
}