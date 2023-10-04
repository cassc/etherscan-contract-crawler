pragma solidity ^0.8.9;

abstract contract SupplyController {
    
    /**
        Called when a claim is successfully issued
     */
    event Claimed(address claimer, uint256 tokenId, uint256 tokensClaimed);


    event Burned(address burner, uint256 tokensBurned);


    /**
      Claims the tokens
     */
    function claim(uint256 tokenId) external virtual;


    /**
       Gets the claimable tokens available for a given NFT
     */
    function getClaimableTokens(address a, uint256 tokenId) external virtual view returns (uint256); 

    /**
     * Gets the last time a user claimed from a token
     * @param addr The address of the user, may be ignored.
     * @param tokenId The token ID claimed
     */
    function getLastClaimed(address addr, uint256 tokenId) external virtual view returns (uint256);

    /**
        Determines based on certain criteria if minting (anything that is able to generate new tokens) is allowed.

        e.g. We have a fixed supply and the current token count would surpass the max amount
     */
    function isMintingAllowed() external virtual view returns (bool);


    /**
       Determines based on certain criteria if burning is allowed.  
     */     
    function isBurningAllowed() external virtual view returns (bool);


    function getMaxSupply() external virtual view returns (uint256);



    /**
      Events
     */
     function onPreTransfer(address from,
        address to,
        uint256 startTokenId,
        uint256 quantity) external virtual{}


    function onPostTransfer(address from,
        address to,
        uint256 startTokenId,
        uint256 quantity) external virtual{}

}