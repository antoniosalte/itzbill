function newtonRaphson (f, fp, x0, options) {
    var x1, y, yp, tol, maxIter, iter, yph, ymh, yp2h, ym2h, h, hr, verbose, eps;
  
    // Iterpret variadic forms:
    if (typeof fp !== 'function') {
      options = x0;
      x0 = fp;
      fp = null;
    }
  
    options = options || {};
    tol = options.tolerance === undefined ? 1e-7 : options.tolerance;
    eps = options.epsilon === undefined ? 2.220446049250313e-16 : options.epsilon;
    maxIter = options.maxIterations === undefined ? 20 : options.maxIterations;
    h = options.h === undefined ? 1e-4 : options.h;
    verbose = options.verbose === undefined ? false : options.verbose;
    hr = 1 / h;
  
    iter = 0;
    while (iter++ < maxIter) {
      // Compute the value of the function:
      y = f(x0);
  
      if (fp) {
        yp = fp(x0);
      } else {
        // Needs numerical derivatives:
        yph = f(x0 + h);
        ymh = f(x0 - h);
        yp2h = f(x0 + 2 * h);
        ym2h = f(x0 - 2 * h);
  
        yp = ((ym2h - yp2h) + 8 * (yph - ymh)) * hr / 12;
      }
  
      // Check for badly conditioned update (extremely small first deriv relative to function):
      if (Math.abs(yp) <= eps * Math.abs(y)) {
        if (verbose) {
          console.log('Newton-Raphson: failed to converged due to nearly zero first derivative');
        }
        return false;
      }
  
      // Update the guess:
      x1 = x0 - y / yp;
  
      // Check for convergence:
      if (Math.abs(x1 - x0) <= tol * Math.abs(x1)) {
        if (verbose) {
          console.log('Newton-Raphson: converged to x = ' + x1 + ' after ' + iter + ' iterations');
        }
        return x1;
      }
  
      // Transfer update to the new guess:
      x0 = x1;
    }
  
    if (verbose) {
      console.log('Newton-Raphson: Maximum iterations reached (' + maxIter + ')');
    }
  
    return false;
  }

var MILLIS_PER_DAY = 1000*60*60*24;
var DAYS_IN_YEAR = 365;

function convert(data) {
    if (!data || !data.length || !data.forEach || data.length < 2) {
        throw new Error('Argument is not an array with length of 2 or more.');
    }

    var investments = [];
    var start = Math.floor(data[0].when/MILLIS_PER_DAY);
    var end = start;
    var minAmount = Number.POSITIVE_INFINITY;
    var maxAmount = Number.NEGATIVE_INFINITY;
    var total = 0;
    var deposits = 0;
    data.forEach(function(datum) {
        total += datum.amount;
        if (datum.amount < 0) {
            deposits += -datum.amount;
        }
        var epochDays = Math.floor(datum.when/MILLIS_PER_DAY);
        start = Math.min(start, epochDays);
        end = Math.max(end, epochDays);
        minAmount = Math.min(minAmount, datum.amount);
        maxAmount = Math.max(maxAmount, datum.amount);
        investments.push({
            amount: datum.amount,
            epochDays: epochDays
        });
    });
    if (start === end) {
        throw new Error('Transactions must not all be on the same day.');
    }
    if (minAmount >= 0) {
        throw new Error('Transactions must not all be nonnegative.');
    }
    if (maxAmount < 0) {
        throw new Error('Transactions must not all be negative.');
    }
    investments.forEach(function(investment) {
        // Number of years (including fraction) this item applies
        investment.years = (end - investment.epochDays) / DAYS_IN_YEAR;
    });
    return {
        total: total,
        deposits: deposits,
        days: end - start,
        investments: investments,
        maxAmount: maxAmount
    };
}

function xirr(transactions, options) {
    var data = convert(transactions);
    if (data.maxAmount === 0) {
        return -1;
    }
    var investments = data.investments;
    var value = function(rate) {
        return investments.reduce(function(sum, investment) {
            // Make the vars more Math-y, makes the derivative easier to see
            var A = investment.amount;
            var Y = investment.years;
            if (-1 < rate) {
                return sum + A * Math.pow(1+rate, Y);
            } else if (rate < -1) {
                // Extend the function into the range where the rate is less
                // than -100%.  Even though this does not make practical sense,
                // it allows the algorithm to converge in the cases where the
                // candidate values enter this range

                // We cannot use the same formula as before, since the base of
                // the exponent (1+rate) is negative, this yields imaginary
                // values for fractional years.
                // E.g. if rate=-1.5 and years=.5, it would be (-.5)^.5,
                // i.e. the square root of negative one half.

                // Ensure the values are always negative so there can never
                // be a zero (as long as some amount is non-zero).
                // This formula also ensures that the derivative is positive
                // (when rate < -1) so that Newton's method is encouraged to 
                // move the candidate values towards the proper range

                return sum - Math.abs(A) * Math.pow(-1-rate, Y);
            } else if (Y === 0) {
                return sum + A;  // Treat 0^0 as 1
            } else {
                return sum;
            }
        }, 0);
    };
    var derivative = function(rate) {
        return investments.reduce(function(sum, investment) {
            // Make the vars more Math-y, makes the derivative easier to see
            var A = investment.amount;
            var Y = investment.years;
            if (Y === 0) {
                return sum;
            } else if (-1 < rate) {
                return sum + A * Y * Math.pow(1+rate, Y-1);
            } else if (rate < -1) {
                return sum + Math.abs(A) * Y * Math.pow(-1-rate, Y-1);
            } else {
                return sum;
            }
        }, 0);
    };
    var guess = options ? options.guess : undefined;
    if (guess && isNaN(guess)) {
        throw new Error("option.guess must be a number.");
    }
    if (!guess) {
        guess = (data.total / data.deposits) / (data.days/DAYS_IN_YEAR);
    }
    var rate = newtonRaphson(value, derivative, guess, options);
    if (rate === false) {  // truthiness strikes again, !rate is true when rate is zero
        throw new Error("Newton-Raphson algorithm failed to converge.");
    }
    return rate;
}

function alertMessage(dates, amounts) {
    dateForXirr = [];
    for (var i = 0; i < dates.length; i++)
    {
        dateStringSplit = dates[i].split('/');
        date = new Date(dateStringSplit[0], dateStringSplit[1], dateStringSplit[2]);
        amount = parseFloat(amounts[i]);
        e =  {'amount': amount, 'when': date};
        dateForXirr.push(e);
    }
    rate = xirr(dateForXirr);
    window.state = {
        xirr: rate
    }
}

window.logger = (flutter_value) => {
    console.log({js_context: this, flutter_value});
}