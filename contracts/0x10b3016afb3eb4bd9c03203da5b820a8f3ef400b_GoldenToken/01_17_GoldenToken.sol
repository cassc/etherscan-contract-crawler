// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./ERC1155Tradable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";


// ██╗    ██╗██╗  ██╗ ██████╗     ██╗███████╗    ▄▄███▄▄· █████╗ ███╗   ███╗ ██████╗ ████████╗    ██████╗
// ██║    ██║██║  ██║██╔═══██╗    ██║██╔════╝    ██╔════╝██╔══██╗████╗ ████║██╔═══██╗╚══██╔══╝    ╚════██╗
// ██║ █╗ ██║███████║██║   ██║    ██║███████╗    ███████╗███████║██╔████╔██║██║   ██║   ██║         ▄███╔╝
// ██║███╗██║██╔══██║██║   ██║    ██║╚════██║    ╚════██║██╔══██║██║╚██╔╝██║██║   ██║   ██║         ▀▀══╝
// ╚███╔███╔╝██║  ██║╚██████╔╝    ██║███████║    ███████║██║  ██║██║ ╚═╝ ██║╚██████╔╝   ██║         ██╗
//  ╚══╝╚══╝ ╚═╝  ╚═╝ ╚═════╝     ╚═╝╚══════╝    ╚═▀▀▀══╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝    ╚═╝         ╚═╝

/**
 * @title SamotGoldenCoin
 * WhoIsSamot - a contract for Samot Golden Coin
 */

abstract contract SamotStaking{

    function stakeOf(address _stakeholder)
        public
        view
        virtual
        returns (uint256[] memory);    
}

contract GoldenToken is ERC1155Tradable {

    using SafeMath for uint256;
    //Addresses
    address constant WALLET1 = 0xffe5CBCDdF2bd1b4Dc3c00455d4cdCcf20F77587;
    address constant WALLET2 = 0xD9CC8af4E8ac5Cb5e7DdFffD138A58Bac49dAEd5;

    // Uint256
    uint256 public maxSupply = 1000;
    uint256 public maxToMint = 1;
    uint256 public maxPerWallet = 1;
    uint256 public constant goldenCoinID = 0;
    uint256 public coinPrice = 1000000000000000000;

    // Booleans
    bool public saleIsActive = false;

    // Contracts
    SamotStaking staked;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _proxyRegistryAddress
    ) ERC1155Tradable(_name, _symbol,_uri,_proxyRegistryAddress) {
        create(0x399Db9b924bC348BfC3bD777817631eb5A79b152, goldenCoinID, 1, "https://samotclub.mypinata.cloud/ipfs/QmTSjZpbh6cX9ZhWp3w21R6ZMdPeBzFda8CdhtrgRxPJtS", "");
    }

    function setStakingContract(address _contract) external onlyOwner {
        staked = SamotStaking(_contract);
    }

    function stakeOf(address _stakeholder)
        public
        view
        returns (uint256[] memory)
    {
        return staked.stakeOf(_stakeholder);
    }


    function setMaxToMint(uint256 _maxToMint) external onlyOwner {
        maxToMint = _maxToMint;
    }

    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setCoinPrice(uint256 _coinPrice) external onlyOwner {
        coinPrice = _coinPrice;
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function reserve(address account, uint256 _id, uint256 _quantity) public onlyOwner{
        _mint(account,_id,_quantity,"");
        tokenSupply[_id] = tokenSupply[_id].add(_quantity);
    }
    
    function mintGoldenCoin(uint256 numberOfTokens) public payable {
        require(saleIsActive, "Sale is not active.");
        require(
            totalSupply(goldenCoinID).add(numberOfTokens) <= maxSupply,
            "Sale has already ended."
        );
        require(numberOfTokens > 0, "numberOfTokens cannot be 0.");
        require(
                coinPrice.mul(numberOfTokens) <= msg.value,
                "ETH sent is incorrect."
            );
        require(
                balanceOf(msg.sender,goldenCoinID).add(numberOfTokens) <= maxPerWallet,
                "Exceeds limit."
            );
        require(
                coinPrice.mul(numberOfTokens) <= msg.value,
                "ETH sent is incorrect."
            );
        require(
                numberOfTokens <= maxToMint,
                "Exceeds per transaction limit."
            );

        for (uint256 i = 0; i < numberOfTokens; i++) {
            _mint(msg.sender,goldenCoinID,numberOfTokens,"");
            tokenSupply[goldenCoinID] = tokenSupply[goldenCoinID].add(numberOfTokens);
        }
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        uint256 wallet1Balance = balance.mul(10).div(100);
        uint256 wallet2Balance = balance.mul(85).div(100);
        payable(WALLET1).transfer(wallet1Balance);
        payable(WALLET2).transfer(wallet2Balance);
        payable(msg.sender).transfer(
            balance.sub(wallet1Balance.add(wallet2Balance))
        );
    }
}