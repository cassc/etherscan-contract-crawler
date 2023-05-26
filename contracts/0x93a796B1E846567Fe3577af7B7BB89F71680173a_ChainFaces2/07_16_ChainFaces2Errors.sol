pragma solidity 0.8.7;

// Sale
error SaleNotOpen();
error NotPreSaleStage();
error NotMainSaleStage();
error SaleNotComplete();
error MainSaleNotComplete();
error AlreadyClaimed();
error InvalidClaimValue();
error InvalidClaimAmount();
error InvalidProof();
error InvalidMintValue();

// NFT
error NonExistentToken();

// Reveal
error InvalidReveal();
error BalanceNotWithdrawn();
error BalanceAlreadyWithdrawn();

// Arena
error LeavingProhibited();
error ArenaIsActive();
error ArenaNotActive();
error ArenaEntryClosed();
error LionsNotHungry();
error LionsAreHungry();
error LastManStanding();
error GameOver();
error InvalidJoinCount();
error NotYourWarrior();