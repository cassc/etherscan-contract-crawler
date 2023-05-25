// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/ISingleMint.sol";
import "./Admins.sol";

abstract contract SingleMint is ISingleMint, Admins {

    /**
    @notice Stock all data about the minting process: sales date, price, max per tx, max per wallet, pause.
    */
    Mint public mints;

    /**
    @notice Stock the count of token minted by a wallet.
    @dev Only used if the max par wallet is > 0.
    */
    mapping(address => uint16) balance;

    /**
    @notice Verify if the minting process is available for a wallet and a token count
    @dev Does not check if it's soldout, only if the wallet can mint (good time, good price, no max per tx/wallet)
    @dev add ~13.000 gas if max per wallet === 0
         add ~32.000 gas if max per wallet > 0 first time
         add ~20.000 gas if max per wallet > 0 next time
    */
    modifier canMint(uint16 _count) virtual {

        require(mintIsOpen(), "Mint not open");
        require(_count <= mints.maxPerTx, "Max per tx limit");
        require(msg.value >= mintPrice(_count), "Value limit");

        if(mints.maxPerWallet > 0){
            require(balance[_msgSender()] + _count <= mints.maxPerWallet, "Max per wallet limit");
            balance[_msgSender()] += _count;
        }
        _;
    }

    /**
    @dev Only owner can update the Mint data: sales date, price, max per tx, max per wallet, pause.
    */
    function setMint(Mint memory _mint) public override onlyOwnerOrAdmins {
        mints = _mint;
        emit EventSaleChange(_mint);
    }

    /**
    @notice Shortcut for change only the pause variable of the Mint struct
    @dev Only owner can pause the mint
    */
    function pauseMint(bool _pause) public override onlyOwnerOrAdmins {
        mints.paused = _pause;
    }

    /**
    @notice Check if the mint process is open, by checking the block.timestamp
    @return True if sales date are between Mint.start and Mint.end
    */
    function mintIsOpen() public view override returns(bool){
        return mints.start > 0 && uint64(block.timestamp) >= mints.start && uint64(block.timestamp) <= mints.end  && !mints.paused;
    }

    /**
    @notice Calculation of the current token price
    */
    function mintPrice(uint256 _count) public view virtual override returns (uint256){
        return mints.price * _count;
    }

    /**
    @return The amount of token minted by the _wallet
    */
    function mintBalance(address _wallet) public view override returns(uint16){
        return balance[_wallet];
    }
}