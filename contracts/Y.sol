pragma solidity 0.4.19;

contract Y {
    address payee;
    Proportion public donationProportion;
    struct Proportion {
        uint num; // numerator
        uint denom; // denominator
    } // e.g. 25% (25/100, or 0.25) is represented as Proportion(25, 100)

    function Y(uint num, uint denom) public {
        require(0 < num && num < denom); // 0% < num/denom < 100%
        donationProportion = Proportion(num, denom);
        payee = msg.sender;
    }

    function payAndDonate(uint num, uint denom, address donee) external payable returns (bool success) {
        require(num == donationProportion.num && denom == donationProportion.denom);
        require((msg.value * donationProportion.num) / msg.value == donationProportion.num); // OpenZeppelin
        uint donation = (msg.value * donationProportion.num) / donationProportion.denom;
        payee.transfer(msg.value - donation); // won't underflow, donation always <= msg.value
        donee.transfer(donation);
        return true;
    }

    function setDonationProportion(uint num, uint denom) external {
        require(msg.sender == payee);
        require(0 < num && num < denom); // 0% < num/denom < 100%
        donationProportion = Proportion(num, denom);
    }

    // only needed if wei gets stuck, though that is not expected
    function unstickWei(address recipient, uint wei_) external {
        require(msg.sender == payee);
        recipient.transfer(wei_);
    }

    // function stickWei() external payable {} // only for testing unstickWei
}
