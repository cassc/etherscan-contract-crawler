# @version ^0.3.9
"""
@title bug_bounty
@author yearn.finance
@notice Claim bug bounty
    - call `claim_bug_bounty()` to confirm you are a white hat
    - claim to receive 5k $DAI and keep 10% of $KP3R with no action taken against you
    - offer expires June 25
    - we have gathered info about you based on your wallet, activity, and leaked meta-data
    - failure to claim means we take next steps with LE
"""

from vyper.interfaces import ERC20

interface Guard:
    def pendingManager() -> address: view
    def pendingGovernor() -> address: view
    def overrideGuardChecks() -> bool: view
    def acceptGovernor(): nonpayable
    def acceptManager(): nonpayable
    def setPendingGovernor(governor: address): nonpayable
    def setPendingManager(manager: address): nonpayable


governance: public(constant(address)) = 0xFEB4acf3df3cDEA7399794D0869ef76A6EfAff52
thekeep3r: public(constant(address)) = 0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83
seeder: public(constant(address)) = 0xcc4bFe86a696D81126AB4C30cb94Ee886E283D01
guard: public(constant(address)) = 0xa6A8B8F06835d44E53Ae871b2EadbE659c335e5d

whitehacker: public(constant(address)) = 0x4941F075d77708b819e9f630f65D65c3289e7C9E
deadline: public(constant(uint256)) = 1687651200 # Sun Jun 25 2023 04:00:00 GMT+0000

kp3r: public(constant(address)) = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44
kp3r_amount: public(constant(uint256)) = 3675613046688720208834 # 10% bounty
dai: public(constant(address)) = 0x6B175474E89094C44Da98b954EedeAC495271d0F
dai_amount: public(constant(uint256)) = 5000 * 10 ** 18


@external
def __init__():
    pass


@external
def claim_bug_bounty():
    assert block.timestamp <= deadline # dev: too late
    assert Guard(guard).overrideGuardChecks() # dev: !overrideGuardChecks

    ERC20(kp3r).transferFrom(whitehacker, thekeep3r, kp3r_amount)

    assert Guard(guard).pendingManager() == self # dev: !self
    assert Guard(guard).pendingGovernor() == self # dev: !self

    Guard(guard).acceptGovernor()
    Guard(guard).acceptManager()

    Guard(guard).setPendingGovernor(governance)
    Guard(guard).setPendingManager(governance)

    assert ERC20(dai).allowance(seeder, self) == dai_amount # dev: !exact amount
    ERC20(dai).transferFrom(seeder, whitehacker, dai_amount)