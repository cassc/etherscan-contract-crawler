//SPDX-License-Identifier: MIT
/**
 * @title LiveMintEnabled
 * @dev @brougkr
 * note: This Contract Is Used To Enable LiveMint To Purchase Tokens From Your Contract
 * note: This Contract Should Be Imported and Included In The `is` Portion Of The Contract Declaration, ex. `contract NFT is Ownable, LiveMintEnabled`
 * note: You Can Copy Or Modify The Example Functions Below To Implement The Two Functions In Your Contract
 */
pragma solidity 0.8.19;
abstract contract LiveMintEnabled
{
    /**
     * @dev LiveMint purchaseTo
     * note: Should Be Implemented With onlyLiveMint Access Modifier
     * note: Should Return The TokenID Being Transferred To The Recipient
     */
    function purchaseTo(address Recipient) external virtual returns (uint tokenID);

    // purchaseTo() EXAMPLE: 
    // Here Is An Example Of The Function Implemented In An Standard ERC721 Contract (you can copy paste the function below into your contract)
    // function purchaseTo(address Recipient) override virtual external onlyLiveMint returns (uint tokenID) 
    // {
    //     _mint(Recipient, 1);
    //     return (totalSupply() - 1);
    // }

    /**
     * @dev ChangeLiveMintAddress Changes The LiveMint Address | note: Should Be Implemented To Include onlyOwner Or Similar Access Modifier
     */
    function _ChangeLiveMintAddress(address LiveMintAddress) external virtual;

    // _ChangeLiveMintAddress EXAMPLE: 
    // Here Is An Example Of The Function Implemented In An Standard ERC721 Contract (you can copy paste the function below into your contract)
    // function _ChangeLiveMintAddress(address LiveMintAddress) override virtual external onlyOwner { _LIVE_MINT_ADDRESS = LiveMintAddress; }

    /**
     * @dev LiveMint Address
     */
    address public _LIVE_MINT_ADDRESS = 0x76375092724A9cE835d117106E0F374E85EFa42B; 

    /**
     * @dev Access Modifier For LiveMint
     */
    modifier onlyLiveMint
    {
        require(msg.sender == _LIVE_MINT_ADDRESS, "onlyLiveMint: msg.sender Is Not The LiveMint Contract");
        _;
    }
}